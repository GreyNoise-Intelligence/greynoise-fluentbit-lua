local greynoise = require 'greynoise'

describe("check_ip handler", function()
    it("tests check_ip handler with valid IPv4", function()
        ip = '89.248.172.16'
        local r = greynoise.check_ip(ip)
        assert.True(r)
    end)
    it("tests check_ip handler with private IPv4", function()
        ip = '192.168.100.1'
        local r = greynoise.check_ip(ip)
        assert.False(r)
    end)
    it("tests check_ip handler with localhost IPv4", function()
        ip = '127.0.0.1'
        local r = greynoise.check_ip(ip)
        assert.False(r)
    end)
    it("tests check_ip handler with multicast IPv4", function()
        ip = '224.0.2.1'
        local r = greynoise.check_ip(ip)
        assert.False(r)
    end)
    it("tests check_ip handler with private IPv6", function()
        ip = '2001:0db8:85a3:0000:0000:8a2e:0370:7334'
        local r = greynoise.check_ip(ip)
        assert.False(r)
    end)
    it("tests check_ip handler with valid IPv6", function()
        ip = '2a03:2880:f003:c07:face:b00c::2'
        local r = greynoise.check_ip(ip)
        assert.False(r)
    end)
    it("tests check_ip handler with nil source_ip", function()
        ip = nil
        local r = greynoise.check_ip(ip)
        assert.False(r)
    end)
    it("tests check_ip handler with non IPv4/IPv6 source_ip", function()
        ip = '1.2.3.test_junk_source_ip'
        local r = greynoise.check_ip(ip)
        assert.False(r)
    end)
  end)

describe("check_if_drop handler", function()
    it("tests check_if_drop handler with t/t/t/t", function()
        local record = {}
        record['gn_riot'] = true
        record['gn_quick'] = true
        local r = greynoise.check_if_drop("true", "true", record)
        assert.True(r)
    end)
    it("tests check_if_drop handler with f/f/t/t", function()
        local record = {}
        record['gn_riot'] = true
        record['gn_quick'] = true
        local r = greynoise.check_if_drop("false", "false", record)
        assert.False(r)
    end)
    it("tests check_if_drop handler with t/f/t/t", function()
        local record = {}
        record['gn_riot'] = true
        record['gn_quick'] = true
        local r = greynoise.check_if_drop("true", "false", record)
        assert.True(r)
    end)
    it("tests check_if_drop handler with f/t/t/t", function()
        local record = {}
        record['gn_riot'] = true
        record['gn_quick'] = true
        local r = greynoise.check_if_drop("false", "true", record)
        assert.True(r)
    end)
    it("tests check_if_drop handler with t/t/f/f", function()
        local record = {}
        record['gn_riot'] = false
        record['gn_quick'] = false
        local r = greynoise.check_if_drop("true", "true", record)
        assert.False(r)
    end)
    it("tests check_if_drop handler with f/f/f/f", function()
        local record = {}
        record['gn_riot'] = false
        record['gn_quick'] = false
        local r = greynoise.check_if_drop("false", "false", record)
        assert.False(r)
    end)
  end)
