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

local greynoise = {_version = '0.1.1'}

local cache_size = tonumber(os.getenv('GREYNOISE_LUA_CACHE_SIZE'))
local gn_api_key = os.getenv('GREYNOISE_API_KEY')
local ip_field = os.getenv('GREYNOISE_IP_FIELD')
log.level = os.getenv('GREYNOISE_LUA_LOG_LEVEL')

local cache = lru.new(cache_size)

local useragent = string.format('GreyNoiseFluentBit/%s', greynoise._version)
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
  local gn_keys = {"gn_noise", "gn_riot", "gn_bogon", "gn_invalid"}
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

-- Lookup a source_ip against `/v3/community` endpoint
--
-- @string ip
-- @return boolean, boolean
local function gn_community_lookup(ip)
  local url = string.format('https://api.greynoise.io/v3/community/%s', ip)
  local response = requests.get {url, headers = headers, auth = auth}
  if (not response) then
    log.warn('no response from /v3/community endpoint')
    return nil, nil
  end
  if response.status_code == 200 then
    local body, error = response.json()
    if error ~= nil then
      log.warn('%v', error)
      return nil, nil
    end
    return body.noise, body.riot
  end
  if response.status_code == 404 then
      local body, error = response.json()
      if error ~= nil then
        log.warn('%v', error)
        return nil, nil
      end
      log.debug(string.format('%s, %s',url, body.message))
      return false, false
  end

  log.warn(string.format('Received %d status code from %s',
                         response.status_code, url))
  return nil, nil
end

-- Main filter handler
--
-- @string _
-- @number timestamp
-- @table  record
-- @return number, number, table
function gn_filter(_, timestamp, record)
  -- Extract IPv4 from message
  local ip = record[ip_field]:match("(%d+%.%d+%.%d+%.%d+)")
  local new_record = record
  new_record.gn_riot = nil
  new_record.gn_noise = nil
  new_record.gn_invalid = nil
  new_record.gn_bogon = nil
  if ip then
    local cache_record = cache:get(ip)
    if cache_record then
      log.debug(string.format('cache hit: %s', ip))
      new_record.gn_riot = cache_record['r']
      new_record.gn_noise = cache_record['q']
      new_record.gn_invalid = cache_record['i']
      new_record.gn_bogon = cache_record['b']
      local final_record = convert_record_bools(new_record)
      return 1, timestamp, final_record
    else
      local validated_record = check_ip(new_record, ip)
      log.debug(string.format('lookup: %s', ip))
      if (not validated_record.gn_invalid and not validated_record.gn_bogon) then
        -- Make GN API calls for valid non-bogon IPv4 records
        validated_record.gn_noise, validated_record.gn_riot = gn_community_lookup(ip)
        if not validated_record.gn_noise == nil or not validated_record.gn_riot == nil then
          return -1, timestamp, final_record
        end
        cache:set(ip, {
          r = validated_record.gn_riot,
          q = validated_record.gn_noise,
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
