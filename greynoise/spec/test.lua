-- luacheck: std max+busted
local greynoise = require 'greynoise'

describe('check_ip handler', function()
  it('tests check_ip handler with valid IPv4', function()
    ip = '89.248.172.16'
    local record = {}
    local v = greynoise.check_ip(record, ip)
    assert.False(v.gn_invalid)
  end)
  it('tests check_ip handler with private IPv4', function()
    ip = '192.168.100.1'
    local record = {}
    local v = greynoise.check_ip(record, ip)
    assert.True(v.gn_bogon)
  end)
  it('tests check_ip handler with localhost IPv4', function()
    ip = '127.0.0.1'
    local record = {}
    local v = greynoise.check_ip(record, ip)
    assert.True(v.gn_bogon)
  end)
  it('tests check_ip handler with multicast IPv4', function()
    ip = '224.0.2.1'
    local record = {}
    local v = greynoise.check_ip(record, ip)
    assert.True(v.gn_bogon)
  end)
  it('tests check_ip handler with private IPv6', function()
    ip = '2001:0db8:85a3:0000:0000:8a2e:0370:7334'
    local record = {}
    local v = greynoise.check_ip(record, ip)
    assert.True(v.gn_invalid)
  end)
  it('tests check_ip handler with valid IPv6', function()
    ip = '2a03:2880:f003:c07:face:b00c::2'
    local record = {}
    local v = greynoise.check_ip(record, ip)
    assert.True(v.gn_invalid)
  end)
  it('tests check_ip handler with nil source_ip', function()
    ip = nil
    local record = {}
    local v = greynoise.check_ip(record, ip)
    assert.True(v.gn_invalid)
  end)
  it('tests check_ip handler with non IPv4/IPv6 source_ip', function()
    ip = '1.2.3.test_junk_source_ip'
    local record = {}
    local v = greynoise.check_ip(record, ip)
    assert.True(v.gn_invalid)
  end)
end)
