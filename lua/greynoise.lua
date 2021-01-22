package.path = package.path .. ";/app/lua/?.lua"
local requests = require('requests')
local json = require ("cjson")
local log = require 'log'
local iputil = require 'iputil'
local lru = require "lru"
local toboolean = require('toboolean')

-- Environment Variables
local cache_size = tonumber(os.getenv("GREYNOISE_LUA_CACHE_SIZE"))
local gn_api_key = os.getenv("GREYNOISE_API_KEY")
local ip_field = os.getenv("GREYNOISE_IP_FIELD")
local drop_riot = toboolean(os.getenv("GREYNOISE_DROP_RIOT_IN_FILTER"))
local drop_quick = toboolean(os.getenv("GREYNOISE_DROP_QUICK_IN_FILTER"))
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

function check_ip(ip)
    local restricted_ranges = Set { "unspecified", "broadcast", "multicast", "linklocal", "loopback",
                                    "private", "reserved", "uniqueLocal", "ipv4Mapped", "rfc6145",
                                    "rfc6052", "6to4", "teredo" }
    -- parse ip into metatable
    local valid = iputil.valid(ip)
    if (not valid) then
        -- skip because ip is not valid
        log.warn('not a valid IP', ip)
        return false
    end

    local ip = iputil.parse(ip)
    if ip then
        new_record = record
        if ip:kind() ~= 'ipv4' then
            log.warn("not supported IP kind")
            return false
        end
        if restricted_ranges[ip:range()] then
            -- skip because ip is not public
            log.warn('not a public IP', ip)
            return false
        end
        return true
    else
        -- skip because we we're unable to parse even though this
        -- was valid per iputil
        log.warn('unable to parse as IPv4 for', ip)
        return false
    end
end

--  Lookup a source_ip against `/v2/riot/` endpoint
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

--  Check if ENV is configured to drop and evaulute quick/riot for drops
function check_if_drop(record)
    if drop_riot and record["gn_riot"] then
        return true
    end
    if drop_quick and record["gn_quick"] then
        return true
    end
    return false
end

--  Lookup a source_ip against `/v2/noise/quick/` endpoint
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

--  Main filter handler
function gn_filter(tag, timestamp, record)
    ip = record[ip_field]
    if ip then
        local new_record = record
        cache_record = cache:get(ip)
        if cache_record then
            log.debug(string.format("cache hit: %s", ip))
            new_record["gn_riot"] = cache_record["r"]
            new_record["gn_quick"] = cache_record["q"]
            if check_if_drop(new_record) then
                return -1, 0, 0
            else
                return 1, timestamp, new_record
            end
        else
            if (check_ip(ip)) then
                log.debug(string.format("lookup: %s", ip))
                new_record["gn_riot"] = gn_riot_check(ip)
                new_record["gn_quick"] = gn_quick_check(ip)
                cache:set(ip, { r =  new_record["gn_riot"], q =  new_record["gn_quick"] })
                if check_if_drop(new_record) then
                    return -1, 0, 0
                else
                    return 1, timestamp, new_record
                end
            end
        end
    else
        return -1, timestamp, new_record
    end
    return -1, timestamp, new_record
end

-- ### FLUENTBIT HANDLERS ###

greynoise.gn_filter = gn_filter

return greynoise