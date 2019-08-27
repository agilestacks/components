#!/usr/bin/env lua

local log = require('lib/log')
local json = require('lib/json')
local yaml = require('lib/yaml')
local config = {
  object = 'deephorizon-config',
  cache = '/tmp/config',
  data = {}
}
log.level = os.getenv('LOG_LEVEL') or 'trace'

if arg[1] == '--config' then
  -- shell-operator takes config as JSON printed to stdout
  print(json.encode({
    onKubernetesEvent = {
      {
        kind = 'ConfigMap',
        event = {
          'add', 'update', 'delete'
        },
        objectName = config.object
      },
      {
        kind = 'Service',
        event = {
          'add', 'update', 'delete'
        },
        jqFilter = '.status.loadBalancer.ingress[]?.ip'
      },
      {
        kind = 'Ingress',
        event = {
          'add', 'update', 'delete'
        }
      }
    },
    schedule = {
      {
        name = 'externalIpScan',
        crontab = '0 */2 * * * *',
        allowFailure = true
      }
    }
  }))
  return 0
end

-------------------------------------------------------------------------------

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

-- return contents of a file handle
local function readHandle(fh)
  local contents = assert(fh:read('*a'))
  fh:close()
  return contents
end

-- return contents of a file name
local function readFile(name)
  local handle = assert(io.open(name, 'rb'))
  return readHandle(handle)
end

-- write content to a file
local function writeFile(name, content)
  local fh = assert(io.open(name, 'w+'))
  fh:write(content)
  fh:close()
end

-- execute nsupdate with the supplied commands
local function nsupdate(commands)
  log.debug('nsupdate = '..commands)
  local debug = '' -- or, ' -d' for nsupdate to display debug output
  local result = os.execute(
    string.format(
      'cat << EOF | nsupdate%s\n%s\nEOF',
      debug, commands
    )
  )
  if result ~= 0 then
    log.error('nsupdate command did not succeed, exit code: '..result)
  end
  return result
end

-- short query the DNS server for 'type' records using dig
local function dig(server, name, type, view)
  local tsig = ''
  type = type or 'A' -- default to 'A' record types if undefined
  view = view or nil

  -- use tsig key signing if a view is provided
  if view ~= nil then
    tsig = string.format(
      '-y %s:%s:%s',
      view.hmac, view.keyname, view.key
    )
  end

  local handle = assert(io.popen(
    string.format(
      'dig @%s -p %s -t %s %s +short %s',
      server.addr, server.port, type, name, tsig
    )
  ))
  return readHandle(handle)
end

-- fetch and return a k8s object
local function kubectl(verb, kind, namespace, name)
  local handle = assert(io.popen(
    string.format(
      'kubectl %s %s -n %s -o json %s || echo null',
      verb, kind, namespace, name
    )
  ))
  return json.decode(readHandle(handle))
end

-------------------------------------------------------------------------------

local function loadConfig(config)
  -- check for config file, abort if it is not available
  if fileExists(config.cache) then
    -- loads config from cache
    config.data = assert(yaml.eval(
      json.decode(
        readFile(config.cache)
      ).data.config
    ))
  else
    log.error('no configuration defined yet, aborting.')
    return false
  end
  log.debug('config = '..json.encode(config))
  return true
end

-- fetch and return the k8s object based on event info
local function getK8sObj(event)
  local result = nil
  if event.resourceEvent == 'add' or event.resourceEvent == 'update' then
    result = kubectl('get', event.resourceKind, event.resourceNamespace, event.resourceName)
  end
  log.debug('k8sObj = '..json.encode(result))
  return result
end

-- given a kubernetes object, return it's external IPs, if any
local function getExternalIp(k8sObj)
  if k8sObj == nil then return nil end
  if k8sObj.kind == 'Service' then
    if k8sObj.status.loadBalancer.ingress then
      return k8sObj.status.loadBalancer.ingress[1].ip or nil
    end
  elseif k8sObj.kind == 'Ingress' then
    log.warn('ingress objects are not yet supported...')
  else
    log.error('illegal object kind: '..k8sObj.kind)
  end
  return nil
end

-- build the view changes and feed result to generate entire update
local function generateViews(config, event, k8sObj)
  local cmd = {}
  local ip = getExternalIp(k8sObj)
  local name = string.format(
    '%s.%s.%s.%s',
    event.resourceName, event.resourceNamespace, config.cluster, config.zone
  )

  -- init all of the views
  for _,view in ipairs(config.views) do
    table.insert(cmd, {string.format(
      "key %s:%s %s\nupdate delete %s",
      view.hmac, view.keyname, view.key, name
    )})
  end

  -- by default we delete records associated with the IP
  -- if the IP is not nil, then we will be adding records
  if ip ~= nil then
    -- add the unmapped IP to the default view, regardless of poolMap matches
    table.insert(cmd[1], string.format(
      'update add %s. 60 IN A %s',
      name, ip
    ))

    -- then, evaluate the IP against the optional pool mappings
    for _,map in ipairs(config.poolMap) do
      -- check if we have a match
      -- only supporting literal matches right now
      if ip == map[1] then
        -- we have a match so apply each mapped IP to its corresponding view
        for i = 2,#config.views do
          -- skip any blank elements
          if (map[i] or '') ~= '' then
            -- create the update entry
            table.insert(cmd[i], string.format(
              'update add %s. 60 IN A %s',
              name, map[i]
            ))
          end
        end
      end
    end
  end

  -- close all of the views
  local output = {}
  for i,view in ipairs(config.views) do
    table.insert(cmd[i], 'send')
    table.insert(output, table.concat(cmd[i], "\n"))
  end

  return table.concat(output, "\n")
end

-- construct update command for all servers
local function generateUpdate(config, event, k8sObj)
  local views = generateViews(config, event, k8sObj)
  local cmd = {}

  -- update each server
  for _,server in ipairs(config.servers) do
    table.insert(cmd, string.format(
      "server %s %s\nzone %s",
      server.addr, server.port, config.zone
    ))

    -- add the views to the general command
    table.insert(cmd, views)
    table.insert(cmd, 'quit')
  end

  return table.concat(cmd, "\n")
end

-- iterate through all servers and views, query for cluster-level canaries
local function getCanaries(config)
  local gotAll = true
  local canary = string.format(
    '_deephorizon_canary.%s.%s.',
    config.cluster, config.zone
  )
  for _,server in ipairs(config.servers) do
    for _,view in ipairs(config.views) do
      local result = dig(server, canary, 'txt', view)
      if result ~= '"ok"\n' then
        -- the canary is dead
        gotAll = false
        log.warn(string.format(
          'the canary is dead in view=%s on server=%s',
          view.keyname, server.addr
        ))
      end
    end
  end

  return gotAll
end

-- set/update the canary on the server
local function setCanaries(config)
  local cmd = {}
  local canary = string.format(
    '_deephorizon_canary.%s.%s. 60 IN TXT "ok"',
    config.cluster, config.zone
  )

  log.info('setting canaries')
  for _,server in ipairs(config.servers) do
    table.insert(cmd, string.format(
      'server %s %s\nzone %s',
      server.addr, server.port, config.zone
    ))

    for _,view in ipairs(config.views) do
      table.insert(cmd, string.format(
        'key %s:%s %s\nupdate add %s\nsend',
        view.hmac, view.keyname, view.key, canary
      ))
    end

    table.insert(cmd, 'quit')
  end

  nsupdate(table.concat(cmd, "\n"))
end

-- scan kubernetes for all external IPs, then add to DNS
local function scanExternalIps()
  log.info('scanning kubernetes for external IPs...')
  -- os.execute does not make stdout available in all versions of Lua
  -- so using a tmp file instead
  local result = os.execute(
    "kubectl get services --all-namespaces -o json | \
    jq -c '[.items[] | select(.status.loadBalancer.ingress[]?.ip)]' > /tmp/scan"
  )
  if result ~= 0 then
    log.error('could not scan for external IPs, return code = '..result)
    return nil
  end
  local k8sObjs = assert(json.decode(readFile('/tmp/scan')))

  -- perform the updates
  log.debug('creating all DNS entries')
  for _,obj in ipairs(k8sObjs) do
    nsupdate(generateUpdate(config.data, {
      resourceName = obj.metadata.name,
      resourceNamespace = obj.metadata.namespace
    }, obj))
  end
end

-------------------------------------------------------------------------------
-- parse the event that triggered this script and react to it

local eventContext = os.getenv('BINDING_CONTEXT_PATH')
if eventContext == nil then
  log.error('event context is missing')
  return 1
end
local events = readFile(eventContext)
log.debug('events = '..events)

for _,event in ipairs(assert(json.decode(events))) do
  -- fetch the object that triggered the event
  local k8sObj = getK8sObj(event)

  if event.binding == 'onKubernetesEvent' then
    -- deals with the configmap
    if event.resourceKind == 'ConfigMap' then
      if event.resourceEvent == 'delete' then
        log.info('removing the configmap cache file')
        os.remove(config.cache)
      else
        log.info('caching new/updated configmap to file')
        writeFile(config.cache, json.encode(k8sObj))
      end
    elseif loadConfig(config) then
      if not getCanaries(config.data) then
        setCanaries(config.data)
      end
      -- exec an nsupdate message
      return nsupdate(generateUpdate(config.data, event, k8sObj))
    else
      log.warn('no-op event = '..json.encode(event))
    end
  elseif event.binding == 'externalIpScan' and loadConfig(config) then
    -- do a canary check
    if not getCanaries(config.data) then
      setCanaries(config.data)
      -- run a scan/update cycle if the canary was dead
      scanExternalIps()
    end
  else
    log.warn('no-op event = '..json.encode(event))
  end
end

return 0
