local config = import "config.json";
local staticPasswords = 
  if std.objectHas(config, "staticPasswords") && config.staticPasswords != null
  then config.staticPasswords else [];

local username = std.extVar("HUB_DEX_USER");
local password = std.extVar("HUB_DEX_PASSWD");

local filterBy(arr, key, desired) =
  local filter(accum, elem) = std.prune(
    accum + [ 
      if std.objectHas(elem, key) 
      && elem[key] != desired
      then arr[std.length(accum)]
    ]
  );
  std.foldl(filter, arr, []);

// see: https://github.com/dexidp/dex/blob/master/storage/storage.go#L301
local optional = if std.length(filterBy(staticPasswords, "email", username)) > 0 
  then [] 
  else [{
    username: username,
    email: username,
    hash: password,
    userID: std.md5(username),
  }];

std.manifestYamlDoc(
  config {
    enablePasswordDB: true,
    staticPasswords: staticPasswords + optional,
    connectors: [
      conn {
        config+:{
          scopes: ["profile", "email", "groups", "openid"]
        }
      }
      for conn in config.connectors
    ],
  }
)
