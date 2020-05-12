local deployment  = import 'deployment.json';
local extDnsImg   = std.extVar("EXTERNALDNS_IMAGE");
local istioNs     = std.extVar("ISTIO_NAMESPACE");
local gwSvc       = std.extVar("ISTIO_GW_SVC");

local findByName(containers, desired) = 
  local indexes(accum, val) = 
    accum + [ if val.name == desired then std.length(accum) else null];
  local a = std.prune(std.foldl(indexes, containers, []));
  if std.length(a) > 0 then a[0] else null;

local hasArg(args, value) = 
  local r = [a for a in args if a == value];
  if std.length(r) > 0 then true else false;

local istioGw     = std.format("--istio-ingress-gateway=%s/%s", [istioNs, gwSvc]);
local gwSrc       = "--source=istio-gateway";
local containers  = deployment.spec.template.spec.containers;
local extDns      = findByName(containers, "external-dns");
assert extDns != null: "Cannot find container: external-dns";

std.prune([
  if !hasArg(containers[extDns].args, gwSrc) then {
    "op": "add",
    "path": std.format("/spec/template/spec/containers/%s/args/0", [extDns]),
    "value": gwSrc,
  },
  if !hasArg(containers[extDns].args, istioGw) then {
    "op": "add",
    "path": std.format("/spec/template/spec/containers/%s/args/0", [extDns]),
    "value": istioGw,
  },
])
