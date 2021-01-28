--
-- Provides FluentBit filter for the GreyNoise API.
--
-- @author    Obsecurus (matt@greynoise.io)
-- @license   MIT
-- @copyright GreyNoise Intelligence Inc. 2021
-- @module greynoise
package.path = package.path .. ';/opt/greynoise/src/?.lua'
local requests = require('requests')
local log = require 'log'
local iputil = require 'iputil'
local lru = require 'lru'

local greynoise = {_version = '0.1.0'}

local cache_size = tonumber(os.getenv('GREYNOISE_LUA_CACHE_SIZE'))
local gn_api_key = os.getenv('GREYNOISE_API_KEY')
local ip_field = os.getenv('GREYNOISE_IP_FIELD')
log.level = os.getenv('GREYNOISE_LUA_LOG_LEVEL')

local cache = lru.new(cache_size)

local useragent = 'GreyNoiseFluentBit/0.0.1'
local auth = requests.HTTPBasicAuth('none', gn_api_key)
local headers = {['User-Agent'] = useragent, ['Accept'] = 'application/json'}

local function has_value(tab, val)
  for _, value in ipairs(tab) do if value == val then return true end end

  return false
end

local function Set(list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

-- Convert record bools to strings for FluentBit rewrite_tag regex
--
-- @table record
-- @return table
local function convert_record_bools(record)
  local gn_keys = {"gn_quick", "gn_riot", "gn_bogon", "gn_invalid"}
  for k, v in pairs(record) do
    if has_value(gn_keys, k) then
      if (v == true) then record[k] = "true" end
      if (v == false) then record[k] = "false" end
    end
  end
  return record
end

-- Check if a given ip string is a valid non-bogon IPv4 address
--
-- @table record
-- @string ip
-- @return table
local function check_ip(record, ip)
  local new_record = record
  new_record.gn_bogon = false
  new_record.gn_invalid = true
  local restricted_ranges = Set {
    'unspecified', 'broadcast', 'multicast', 'linklocal', 'loopback', 'private',
    'reserved', 'uniqueLocal', 'ipv4Mapped', 'rfc6145', 'rfc6052', '6to4',
    'teredo'
  }
  -- parse ip into metatable
  local valid = iputil.valid(ip)
  if (not valid) then
    -- skip because ip is not valid
    log.warn('not a valid IP', ip)
    new_record.gn_invalid = true
    new_record.gn_bogon = false
    return new_record
  end

  local parsed_ip = iputil.parse(ip)
  if parsed_ip then
    if parsed_ip:kind() ~= 'ipv4' then
      log.warn('not a supported IP kind', ip)
      new_record.gn_invalid = true
      new_record.gn_bogon = false
      return new_record
    end
    if restricted_ranges[parsed_ip:range()] then
      -- skip because ip is not public
      log.warn('not a public IP', ip)
      new_record.gn_bogon = true
      new_record.gn_invalid = false
      return new_record
    end
    new_record.gn_invalid = false
    new_record.gn_bogon = false
    return new_record
  end
  -- skip because we we're unable to parse even though this
  -- was valid per iputil
  log.warn('unable to parse as IPv4 for', ip)
  return new_record
end

-- Lookup a source_ip against `/v2/riot/` endpoint
--
-- @string ip
-- @return boolean
local function gn_riot_check(ip)
  local url = string.format('https://api.greynoise.io/v2/riot/%s', ip)
  local response = requests.get {url, headers = headers, auth = auth}
  if (not response) then
    log.warn('no response from /v2/riot/ endpoint')
    return nil
  end
  if response.status_code == 200 then
    local body, error = response.json()
    if error ~= nil then
      log.warn('%v', error)
      return nil
    end
    if body.riot == true then return true end
    return false
  elseif response.status_code == 404 then
    -- RIOT uses a soft 404 to represent that resource is not in RIOT.
    -- This interface differs from the `v2/noise/quick` endpoint that returns 200 for all requested IPs.
    return false
  end

  log.warn(string.format('Received %d status code from %s',
                         response.status_code, url))
  return nil
end

-- Lookup a source_ip against `/v2/noise/quick/` endpoint
--
-- @string ip
-- @return boolean
local function gn_quick_check(ip)
  local url = string.format('https://api.greynoise.io/v2/noise/quick/%s', ip)
  local response = requests.get {url, headers = headers, auth = auth}
  if (not response) then
    log.warn('no response from /v2/noise/quick/ endpoint')
    return nil
  end
  if response.status_code == 200 then
    local body, error = response.json()
    if error ~= nil then
      log.warn('%v', error)
      return nil
    end
    if body.noise == true then return true end
    return false
  end

  log.warn(string.format('Received %d status code from %s',
                         response.status_code, url))
  return nil
end

-- Main filter handler
--
-- @string _
-- @number timestamp
-- @table  record
-- @return number, number, table
function gn_filter(_, timestamp, record)
  local ip = record[ip_field]
  local new_record = record
  new_record.gn_riot = nil
  new_record.gn_quick = nil
  new_record.gn_invalid = nil
  new_record.gn_bogon = nil
  if ip then
    local cache_record = cache:get(ip)
    if cache_record then
      log.debug(string.format('cache hit: %s', ip))
      new_record.gn_riot = cache_record['r']
      new_record.gn_quick = cache_record['q']
      new_record.gn_invalid = cache_record['i']
      new_record.gn_bogon = cache_record['b']
      local final_record = convert_record_bools(new_record)
      return 1, timestamp, final_record
    else
      local validated_record = check_ip(new_record, ip)
      log.debug(string.format('lookup: %s', ip))
      if (not validated_record.gn_invalid and not validated_record.gn_bogon) then
        -- Make GN API calls for valid non-bogon IPv4 records
        validated_record.gn_riot = gn_riot_check(ip)
        validated_record.gn_quick = gn_quick_check(ip)
        cache:set(ip, {
          r = validated_record.gn_riot,
          q = validated_record.gn_quick,
          i = validated_record.gn_invalid,
          b = validated_record.gn_bogon
        })
      end
      local final_record = convert_record_bools(validated_record)
      return 1, timestamp, final_record
    end
  end
  local final_record = convert_record_bools(new_record)
  return -1, timestamp, final_record
end

greynoise.check_ip = check_ip
greynoise.gn_filter = gn_filter

return greynoise
