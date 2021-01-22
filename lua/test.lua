local greynoise = require 'greynoise'
local uuid = require 'resty.jit-uuid'

function copy(obj, seen)
    -- copies a lua table from an existing table and returns the new table unpacked
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
    return res
  end

describe("greynoise module", function()
    it("tests greynoise module import", function()
        assert.is_truthy(package.loaded.greynoise)
    end)
  end)

describe("gen_uuid handler", function()
    local tag = 'hassh'
    local timestamp = 1583338899
    local record = {}
    it("tests gen_uuid handler returns valid UUID4", function()
        local r_code, r_timestamp, r_record = greynoise.gen_uuid(tag, timestamp, record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.True(uuid.is_valid(record['event_uuid']))

    end)
  end)

describe("check_ip handler", function()
    it("tests check_ip handler with valid sensor public IP", function()
        local tag = 'hassh'
        local timestamp = 1583338899
        local record = {}
        record['source_ip'] = '1.2.3.4'
        local r_code, r_timestamp, r_record = greynoise.check_ip(tag, timestamp, record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
    end)
    it("tests check_ip handler with valid IPv4", function()
        local tag = 'hassh'
        local timestamp = 1583338899
        local record = {}
        record['source_ip'] = '89.248.172.16'
        local r_code, r_timestamp, r_record = greynoise.check_ip(tag, timestamp, record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.True(record['ip_version'] == 4)
    end)
    it("tests check_ip handler with private IPv4", function()
        local tag = 'hassh'
        local timestamp = 1583338899
        local record = {}
        record['source_ip'] = '192.168.100.1'
        local r_code, r_timestamp, r_record = greynoise.check_ip(tag, timestamp, record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(record['ip_version'] == 4)
    end)
    it("tests check_ip handler with localhost IPv4", function()
        local tag = 'hassh'
        local timestamp = 1583338899
        local record = {}
        record['source_ip'] = '127.0.0.1'
        local r_code, r_timestamp, r_record = greynoise.check_ip(tag, timestamp, record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(record['ip_version'] == 4)
    end)
    it("tests check_ip handler with multicast IPv4", function()
        local tag = 'hassh'
        local timestamp = 1583338899
        local record = {}
        record['source_ip'] = '224.0.2.1'
        local r_code, r_timestamp, r_record = greynoise.check_ip(tag, timestamp, record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(record['ip_version'] == 4)
    end)
    it("tests check_ip handler with VPN IPv4", function()
        local tag = 'hassh'
        local timestamp = 1583338899
        local record = {}
        record['source_ip'] = '3.215.138.152'
        local r_code, r_timestamp, r_record = greynoise.check_ip(tag, timestamp, record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
    end)
    it("tests check_ip handler with private IPv6", function()
        local tag = 'hassh'
        local timestamp = 1583338899
        local record = {}
        record['source_ip'] = '2001:0db8:85a3:0000:0000:8a2e:0370:7334'
        local r_code, r_timestamp, r_record = greynoise.check_ip(tag, timestamp, record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(record['ip_version'] == 6)
    end)
    it("tests check_ip handler with valid IPv6", function()
        local tag = 'hassh'
        local timestamp = 1583338899
        local record = {}
        record['source_ip'] = '2a03:2880:f003:c07:face:b00c::2'
        local r_code, r_timestamp, r_record = greynoise.check_ip(tag, timestamp, record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.True(record['ip_version'] == 6)
    end)
    it("tests check_ip handler with nil source_ip", function()
        local tag = 'hassh'
        local timestamp = 1583338899
        local record = {}
        record['source_ip'] = nil
        local r_code, r_timestamp, r_record = greynoise.check_ip(tag, timestamp, record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
    end)
    it("tests check_ip handler with non IPv4/IPv6 source_ip", function()
        local tag = 'hassh'
        local timestamp = 1583338899
        local record = {}
        record['source_ip'] = '1.2.3.test_junk_source_ip'
        local r_code, r_timestamp, r_record = greynoise.check_ip(tag, timestamp, record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
    end)
  end)

  describe("massage_for_gcs handler", function()
    local tag = 'hassh'
    local timestamp = 1583338899
    local record = {}
    record['timestamp'] = timestamp
    record['event_type'] = 'hassh'
    record['gcs_version'] = 2
    record['project'] = 'collector'
    record['provider'] = 'aws'
    record['region'] = 'us-east-1'
    record['meta_type'] = '-'
    record['session_id'] = '-'
    record['app_protocol'] = 'SSH'
    record['protocol'] = 'TCP'
    record['ip_version'] = 4
    record['3WH'] = 'False'
    record['event_uuid'] = '9d7883f1-64de-4abc-ad50-487cd339f3d9'
    record['sensor_uuid'] = '77352eb3-4ca4-4c3b-aa50-d16edac4245c'
    record['hostname'] = 'ip-172-31-38-49'
    record['event'] = '{"client": "SSH-2.0-libssh-0.6.3", "hassh": "51cba57125523ce4b9db67714a90bf6e", "hasshAlgorithms": "curve25519-sha256@libssh.org,ecdh-sha2-nistp256,diffie-hellman-group14-sha1,diffie-hellman-group1-sha1;aes256-ctr,aes192-ctr,aes128-ctr,aes256-cbc,aes192-cbc,aes128-cbc,blowfish-cbc,3des-cbc,des-cbc-ssh1;hmac-sha1;none", "hasshVersion": "1.0", "ckex": "curve25519-sha256@libssh.org,ecdh-sha2-nistp256,diffie-hellman-group14-sha1,diffie-hellman-group1-sha1", "ceacts": "aes256-ctr,aes192-ctr,aes128-ctr,aes256-cbc,aes192-cbc,aes128-cbc,blowfish-cbc,3des-cbc,des-cbc-ssh1", "cmacts": "hmac-sha1", "ccacts": "none", "clcts": "[Empty]", "clstc": "[Empty]", "ceastc": "aes256-ctr,aes192-ctr,aes128-ctr,aes256-cbc,aes192-cbc,aes128-cbc,blowfish-cbc,3des-cbc,des-cbc-ssh1", "cmastc": "hmac-sha1", "ccastc": "none", "cshka": "ecdsa-sha2-nistp256,ssh-rsa,ssh-dss"}'
    record['source_ip'] = '8.8.8.8'
    record['source_port'] = 44688
    record['sensor_ip'] = '52.201.241.171'
    record['destination_ip'] = '52.201.241.171'
    record['destination_port'] = 22
    it("tests massage_for_gcs handler for converting '-' to empty string", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['meta_type'] == '')
    end)
    it("tests massage_for_gcs handler drops messages without event", function()
        local local_record = copy(record)
        local_record['event'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['event'] == nil)
    end)
    it("tests massage_for_gcs handler drops messages without source_ip", function()
        local local_record = copy(record)
        local_record['source_ip'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['source_ip'] == nil)
    end)
    it("tests massage_for_gcs handler drops messages without sensor_ip", function()
        local local_record = copy(record)
        local_record['sensor_ip'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['sensor_ip'] == nil)
    end)
    it("tests massage_for_gcs handler drops messages without destination_ip", function()
        local local_record = copy(record)
        local_record['destination_ip'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['destination_ip'] == nil)
    end)
    it("tests massage_for_gcs handler drops messages without event_uuid", function()
        local local_record = copy(record)
        local_record['event_uuid'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['event_uuid'] == nil)
    end)
    it("tests massage_for_gcs handler with valid event_uuid", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_string(record['event_uuid'])
        assert.True(uuid.is_valid(record['event_uuid']))
    end)
    it("tests massage_for_gcs handler drops messages without sensor_uuid", function()
        local local_record = copy(record)
        local_record['sensor_uuid'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['sensor_uuid'] == nil)
    end)
    it("tests massage_for_gcs handler with valid sensor_uuid", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_string(record['sensor_uuid'])
        assert.True(uuid.is_valid(record['sensor_uuid']))
    end)
    it("tests massage_for_gcs handler drops messages without hostname", function()
        local local_record = copy(record)
        local_record['hostname'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['hostname'] == nil)
    end)
    it("tests massage_for_gcs handler drops messages without ip_version", function()
        local local_record = copy(record)
        local_record['ip_version'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['ip_version'] == nil)
    end)
    it("tests massage_for_gcs handler drops messages without project", function()
        local local_record = copy(record)
        local_record['project'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['project'] == nil)
    end)
    it("tests massage_for_gcs handler drops messages without provider", function()
        local local_record = copy(record)
        local_record['provider'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['provider'] == nil)
    end)
    it("tests massage_for_gcs handler drops messages without region", function()
        local local_record = copy(record)
        local_record['region'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['region'] == nil)
    end)
    it("tests massage_for_gcs handler drops messages without 3WH", function()
        local local_record = copy(record)
        local_record['3WH'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['3WH'] == nil)
    end)
    it("tests massage_for_gcs handler converts 3WH to proper boolean", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_boolean(r_record['3WH'])
        assert.True(r_record['3WH'] == false)
    end)
    it("tests massage_for_gcs handler convert an existing boolean to boolean", function()
        local local_record = copy(record)
        local_record['3WH'] = true
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_boolean(r_record['3WH'])
        assert.True(r_record['3WH'] == true)
    end)
    it("tests massage_for_gcs handler for non-boolean 3WH", function()
        local local_record = copy(record)
        local_record['3WH'] = 'not-a-boolean'
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
    end)
    it("tests massage_for_gcs handler drops messages without timestamp", function()
        local local_record = copy(record)
        local_record['timestamp'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['timestamp'] == nil)
    end)
    it("tests massage_for_gcs handler drops messages without gcs_version", function()
        local local_record = copy(record)
        local_record['gcs_version'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['gcs_version'] == nil)
    end)
    it("tests massage_for_gcs handler valid gcs_version", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_number(r_record['gcs_version'])
        assert.are.same(r_record['gcs_version'],2)
    end)
    it("tests massage_for_gcs handler drops messages without event_type", function()
        local local_record = copy(record)
        local_record['event_type'] = nil
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['event_type'] == nil)
    end)
    it("tests massage_for_gcs handler with valid source_port", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_number(r_record['source_port'])
        assert.are.same(r_record['source_port'],44688)
    end)
    it("tests massage_for_gcs handler with valid destination_port", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_number(r_record['destination_port'])
        assert.are.same(r_record['destination_port'],22)
    end)
    it("tests massage_for_gcs handler with valid app_protocol", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_string(r_record['app_protocol'])
        assert.are.same(r_record['app_protocol'],"SSH")
    end)
    it("tests massage_for_gcs handler with valid protocol", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.massage_for_gcs(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_string(r_record['protocol'])
        assert.are.same(r_record['protocol'],"TCP")
    end)
  end)

describe("check_valid_hassh handler", function()
    -- This is not a GCSv2 event, however raw HASSH JSON at this point
    local tag = 'hassh'
    local timestamp = 1583338899
    local record = {}
    record['client'] = 'SSH-2.0-libssh-0.6.3'
    it("tests check_valid_hassh handler with valid client", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.check_valid_hassh(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_string(r_record['client'])
        assert.are.same(r_record['client'],"SSH-2.0-libssh-0.6.3")
    end)
    it("tests check_valid_hassh handler drops messages without client", function()
        local local_record = copy(record)
        local_record['client'] = nil
        record['server'] = 'SSH-2.0-OpenSSH_7.2p2 Ubuntu-4ubuntu2.4'
        local r_code, r_timestamp, r_record = greynoise.check_valid_hassh(tag, timestamp, local_record)
        assert.True(r_code == -1)
        assert.True(r_timestamp == timestamp)
    end)
  end)

describe("lookup_protocol handler", function()
    local tag = 'iptables'
    local timestamp = 1583338899
    local record = {}
    record['protocol'] = 6.0
    it("tests lookup_protocol handler with valid protocol", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.lookup_protocol(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_string(r_record['protocol'])
        assert.are.same(r_record['protocol'],"TCP")
    end)
    it("tests lookup_protocol handler just uses nil when it cant find a protocol", function()
        local local_record = copy(record)
        local_record['protocol'] = 600
        local r_code, r_timestamp, r_record = greynoise.lookup_protocol(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['protocol'] == nil)
    end)
  end)

describe("inject_time handler", function()
    local tag = 'iptables'
    local timestamp = 1583338899
    local record = {}
    it("tests inject_time handler for valid timestamp", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.inject_time(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_number(r_record['timestamp'])
        -- We can use os.time for testing here because inject_time injects the current time
        -- not from anything parsed
        assert.True(r_record['timestamp'] <= os.time() and r_record['timestamp'] >= os.time() - 300)
    end)
  end)

describe("add_epoch_timestamp handler", function()
    local tag = 'iptables'
    local timestamp = 1583338899
    local record = {}
    it("tests add_epoch_timestamp handler for valid timestamp", function()
        local local_record = copy(record)
        local r_code, r_timestamp, r_record = greynoise.add_epoch_timestamp(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.is_number(r_record['timestamp'])
        assert.are.same(r_record['timestamp'],1583338899)
    end)
  end)

describe("convert_dot_keys_to_dashes handler", function()
    local tag = 'iptables'
    local timestamp = 1583338899
    local record = {}
    it("tests convert_dot_keys_to_dashes handler for valid conversion", function()
        local local_record = copy(record)
        local_record['key.with.dots'] = 0
        local r_code, r_timestamp, r_record = greynoise.convert_dot_keys_to_dashes(tag, timestamp, local_record)
        assert.True(r_code == 1)
        assert.True(r_timestamp == timestamp)
        assert.True(r_record['key_with_dots'] == 0)
    end)
  end)