--[[
    deep horizon self test
]]

local lust = require('lib/lust')
local json = require('lib/json')
local describe, it, expect = lust.describe, lust.it, lust.expect
local scriptExec = 'lua deephorizon.lua'
local scriptExecEvent = "sh -c 'BINDING_CONTEXT_PATH=/tmp/event.json "..scriptExec.."'"

-------------------------------------------------------------------------------
-- test data

local lastKnownHookConfig = json.decode('{"onKubernetesEvent":[{"kind":"ConfigMap","event":["add","update","delete"],"objectName":"deephorizon-config"},{"kind":"Service","event":["add","update","delete"],"jqFilter":".status.loadBalancer.ingress[]?.ip"},{"kind":"Ingress","event":["add","update","delete"]}],"schedule":[{"allowFailure":true,"crontab":"0 */2 * * * *","name":"externalIpScan"}]}')

--[[
    binding = onKubernetesEvent, externalIpScan
    ns = k8s namespace
    kind = Service, Ingress, ConfigMap
    name = k8s object name
    event = add, update, delete
]]
local function getEvent(binding, ns, kind, name, event)
    return {
        binding = binding,
        resourceNamespace = ns,
        resourceKind = kind,
        resourceName = name,
        resourceEvent = event
    }
end

-------------------------------------------------------------------------------
-- custom test assertions

lust.paths.contain = {
    test = function(v, x)
        return string.find(v, x) ~= nil,
        'expected ' .. tostring(v) .. ' to contain ' .. tostring(x),
        'expected ' .. tostring(v) .. ' to not contain ' .. tostring(x)
    end
}
table.insert(lust.paths.to, 'contain')

lust.paths.json = {
    test = function(v)
        return type(json.decode(v)) == 'table',
        'expected ' .. tostring(v) .. ' to be JSON',
        'expected ' .. tostring(v) .. ' to not be JSON'
    end
}
table.insert(lust.paths.be, 'json')

-------------------------------------------------------------------------------
-- helper functions

-- return contents of a file handle
local function exec(command)
    local fh = assert(io.popen(command))
    local contents = assert(fh:read('*a'))
    fh:close()
    return contents
end

-- write content to a file
local function writeFile(name, content)
    local fh = assert(io.open(name, 'w+'))
    fh:write(content)
    fh:close()
end

-- check if a file exists
local function fileExists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

-------------------------------------------------------------------------------
-- test cases

describe('Deep Horizon', function()

    describe('start up behavior', function()

        it('error out when there is no input provided', function()
            expect(
                exec(scriptExec)
            ).to.contain('ERROR') -- TODO: make more specific
        end)
        it('emits JSON when --config flag is passed as a parameter', function()
            expect(
                exec(scriptExec..' --config')
            ).to.be.json()
        end)
        it('emits correct last known hook config as JSON', function()
            expect(
                json.decode(exec(scriptExec..' --config'))
            ).to.equal(lastKnownHookConfig)
        end)

    end)

    describe('config cache handling', function()

        it('wont handle other delete events until a cached ConfigMap is present', function()
            writeFile('/tmp/event.json', json.encode({
                getEvent('onKubernetesEvent', 'defualt', 'Service', 'kubernetes', 'delete')
            }))
            expect(
                exec(scriptExecEvent)
            ).to.contain('no configuration defined yet, aborting.')
        end)
        it('wont handle other add/update events until a cached ConfigMap is present', function()
            writeFile('/tmp/event.json', json.encode({
                getEvent('onKubernetesEvent', 'defualt', 'Service', 'kubernetes', 'update')
            }))
            expect(
                exec(scriptExecEvent)
            ).to.contain('no configuration defined yet, aborting.')
        end)
        it('caches ConfigMap upon update or add event', function()
            writeFile('/tmp/event.json', json.encode({
                getEvent('onKubernetesEvent', 'deephorizon', 'ConfigMap', 'deephorizon-config', 'add')
            }))
            expect(
                exec(scriptExecEvent)
            ).to.contain('caching new/updated configmap to file')
        end)
        it('actually wrote the ConfigMap to the cache file', function()
            expect(
                fileExists('/tmp/config')
            ).to.equal(true)
        end)
        it('will handle configmap delete events', function()
            writeFile('/tmp/event.json', json.encode({
                getEvent('onKubernetesEvent', 'deephorizon', 'ConfigMap', 'deephorizon-config', 'delete')
            }))
            expect(
                exec(scriptExecEvent)
            ).to.contain('removing the configmap cache file')
        end)
        it('actually deleted the ConfigMap cache file', function()
            expect(
                fileExists('/tmp/config')
            ).to.equal(false)
        end)
    end)

    -- cache a useable config
    writeFile('/tmp/config', string.match([[
        {
            "kind": "ConfigMap",
            "apiVersion": "v1",
            "data": {
                "config": "zone: k8s.agilestacks.vdc\ncluster: cluster1\nservers:\n- addr: 192.168.123.99\n  port: 53\nviews:\n- keyname: k8s_native\n  hmac: hmac-sha512\n  key: 8YYclPBY4CnV/SlG4OZSSMrkR5KokkvpNbbJjhIV/JemLm7J2FOcziQawHt65KUj8S2AWtOW7KWmrpBGfswWrg==\n- keyname: corp_intranet\n  hmac: hmac-sha512\n  key: nvKJxasg7hi40jijuqbywMwPz6JpLzTbo0VbQdPlyUWesfkhujsjBwW3jCe9LVTQk5ReEwiQil5NC4AXX2LUEg==\npoolMap:\n- [ '192.168.123.201', '10.23.45.6', '56.43.21.9' ]\n- [ '192.168.123.202', '10.23.45.16' ]\n- [ '192.168.123.203', '', '56.43.21.19' ]\n"
            }
        }
    ]], '^%s*(.-)%s*$'))

    --[[ TODO
    describe('event handling', function()

        it('foobar', function()
            writeFile('/tmp/event.json', json.encode({
                getEvent('onKubernetesEvent', 'default', 'Service', 'httpbin', 'add')
            }))
            expect(
                exec(scriptExecEvent)
            ).to.contain('foo')
        end)

    end)
    --]]
end)
