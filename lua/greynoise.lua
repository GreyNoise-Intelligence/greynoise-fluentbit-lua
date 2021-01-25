--
-- Provides FluentBit filter for the GreyNoise API.
--
-- @author    Obsecurus (matt@greynoise.io)
-- @license   MIT
-- @copyright GreyNoise Intelligence Inc. 2021
-- @module greynoise

package.path = package.path .. ";./lua/?.lua"
local requests = require('requests')
local json = require ("cjson")
local log = require 'log'
local iputil = require 'iputil'
local lru = require "lru"

local greynoise = { _version = "0.1.0" }

local cache_size = tonumber(os.getenv("GREYNOISE_LUA_CACHE_SIZE"))
local gn_api_key = os.getenv("GREYNOISE_API_KEY")
local ip_field = os.getenv("GREYNOISE_IP_FIELD")
log.level = os.getenv("GREYNOISE_LUA_LOG_LEVEL")

local cache = lru.new(cache_size)

local useragent = "GreyNoiseFluentBit/0.0.1"
local auth = requests.HTTPBasicAuth('none', gn_api_key)
local headers = {
    ['User-Agent'] = useragent,
    ['Accept'] = "application/json"
}

function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
  end

-- Check if a given ip string is a valid non-bogon IPv4 address
--
-- @table record
-- @string ip
-- @return table
function check_ip(record, ip)
    local new_record = record
    local restricted_ranges = Set { "unspecified", "broadcast", "multicast", "linklocal", "loopback",
                                    "private", "reserved", "uniqueLocal", "ipv4Mapped", "rfc6145",
                                    "rfc6052", "6to4", "teredo" }
    -- parse ip into metatable
    local valid = iputil.valid(ip)
    if (not valid) then
        -- skip because ip is not valid
        log.warn('not a valid IP', ip)
        new_record["gn_invalid"] = true
        new_record["gn_bogon"] = false
        return new_record
    end

    local ip = iputil.parse(ip)
    if ip then
        if ip:kind() ~= 'ipv4' then
            log.warn('not a supported IP kind', ip)
            new_record["gn_invalid"] = true
            new_record["gn_bogon"] = false
            return new_record
        end
        if restricted_ranges[ip:range()] then
            -- skip because ip is not public
            log.warn('not a public IP', ip)
            new_record["gn_bogon"] = true
            new_record["gn_invalid"] = false
            return new_record
        end
        new_record["gn_invalid"] = false
        new_record["gn_bogon"] = false
        return new_record
    else
        -- skip because we we're unable to parse even though this
        -- was valid per iputil
        log.warn('unable to parse as IPv4 for', ip)
        new_record["gn_bogon"] = false
        new_record["gn_invalid"] = true
        return new_record
    end
end

-- Lookup a source_ip against `/v2/riot/` endpoint
--
-- @string ip
-- @return boolean
function gn_riot_check(ip)
    headers = {['key'] = gn_api_key, ['User-Agent'] = useragent}
    local url = string.format("https://api.greynoise.io/v2/riot/%s", ip)
    local response = requests.get{url, headers = headers, auth = auth}
    if (not response) then
        log.warn('no response from /v2/riot/ endpoint')
        return false
    end
    if response.status_code == 200  then
        body, error = response.json()
        if error ~= nil then
            log.warn("%v", error)
        end
        if body["riot"] == true then
            return true
        end
    elseif response.status_code == 404  then
        return false
    else
        log.warn(string.format("Received %d status code from %s", response.status_code, url))
        return false
    end
    return false
end

-- Check if ENV is configured to drop and evaulute record for drops
--
-- @string drop_riot
-- @string drop_quick
-- @table record
-- @return boolean
function check_if_drop(drop_riot, drop_quick, drop_bogon, drop_invalid, record)
    if (drop_riot == "true") and record["gn_riot"] then
        return true
    end
    if (drop_quick == "true") and record["gn_quick"] then
        return true
    end
    if (drop_bogon == "true") and record["gn_bogon"] then
        return true
    end
    if (drop_invalid == "true") and record["gn_invalid"] then
        return true
    end
    return false
end

-- Lookup a source_ip against `/v2/noise/quick/` endpoint
--
-- @string ip
-- @return boolean
function gn_quick_check(ip)
    local url = string.format("https://api.greynoise.io/v2/noise/quick/%s", ip)
    local response = requests.get{url, headers = headers, auth = auth}
    if (not response) then
        log.warn('no response from /v2/noise/quick/ endpoint')
        return false
    end
    if response.status_code == 200 then
        body, error = response.json()
        if error ~= nil then
            log.warn("%v", error)
        end
        if body["noise"] == true then
            return true
        end
    else
        log.warn(string.format("Received %d status code from %s", response.status_code, url))
        return false
    end
    return false
end

-- Main filter handler
--
-- @string tag
-- @number timestamp
-- @table  record
-- @return number, number, table
function gn_filter(tag, timestamp, record)
    drop_riot = os.getenv("GREYNOISE_DROP_RIOT_IN_FILTER")
    drop_quick = os.getenv("GREYNOISE_DROP_QUICK_IN_FILTER")
    drop_invalid = os.getenv("GREYNOISE_DROP_INVALID_IN_FILTER")
    drop_bogon = os.getenv("GREYNOISE_DROP_BOGON_IN_FILTER")
    ip = record[ip_field]
    local new_record = record
    if ip then
        cache_record = cache:get(ip)
        if cache_record then
            log.debug(string.format("cache hit: %s", ip))
            new_record["gn_riot"] = cache_record["r"]
            new_record["gn_quick"] = cache_record["q"]
            new_record["gn_invalid"] = cache_record["i"]
            new_record["gn_bogon"] = cache_record["b"]
            if check_if_drop(drop_riot, drop_quick, drop_bogon, drop_invalid, new_record) then
                return -1, 0, 0
            else
                return 1, timestamp, new_record
            end
        else
            local validated_record = check_ip(new_record, ip)
            log.debug(string.format("lookup: %s", ip))
            validated_record["gn_riot"] = gn_riot_check(ip)
            validated_record["gn_quick"] = gn_quick_check(ip)
            cache:set(ip, { r =  validated_record["gn_riot"], q =  validated_record["gn_quick"], i =  validated_record["gn_invalid"], b =  validated_record["gn_bogon"] })
            if check_if_drop(drop_riot, drop_quick, drop_bogon, drop_invalid, validated_record) then
                return -1, 0, 0
            else
                return 1, timestamp, validated_record
            end
        end
    else
        return -1, timestamp, new_record
    end
    return -1, timestamp, new_record
end

greynoise.check_ip = check_ip
greynoise.gn_filter = gn_filter
greynoise.check_if_drop = check_if_drop

return greynoise