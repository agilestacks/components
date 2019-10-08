# Deep Horizon

> *Filling the gulf.*

Keeps RFC2136 compliant DNS servers updated with Kubernetes Ingress and Service IPs. Adds additional capabilities for maintaining arbitrarily complex "split-horizon" views via TSIG keys.

## Operation

Deep Horizon is configured via ConfigMap. Configuration consists of:

* RFC2136 information such as server info, views, TSIG keys, etc
* Mapping of cluster native IPs to arbitrary IPs in other views

A hook that monitors for add, update, or delete events of Ingress or LoadBalancer Kubernetes objects. When a hook is triggered, the ConfigMap is read and `nsupdate` is launched against the target DNS server(s). As an option, Deep Horizon could periodically check if the target DNS servers are up-to-date, and if they are not, apply the result of a scan of Ingress and LoadBalancer IPs.

Programmed names will take the form: `<obj name>.<namespace>.<cluster name>.<delegated zone>`

## Configuration

A Deep Horizon ConfigMap might look something like:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: deephorizon-config
  namespace: deephorizon
data:
  config: |
    zone: k8s.agilestacks.vdc
    cluster: cluster1
    # whether or not the default view should be updated too (eg: if paired with external-dns for instance)
    # configure all servers that should be updated/monitored
    servers:
    - addr: 192.168.123.99
      port: 53
    # an array of views, indexes of which will correlate to the poolMap CSV column indexes (ie: view #1 -> column #1)
    views:
    - keyname: k8s_native
      key: 8YYclPBY4CnV/SlG4OZSSMrkR5KokkvpNbbJjhIV/JemLm7J2FOcziQawHt65KUj8S2AWtOW7KWmrpBGfswWrg==
      hmac: hmac-sha512
    - keyname: corp_intranet
      key: nvKJxasg7hi40jijuqbywMwPz6JpLzTbo0VbQdPlyUWesfkhujsjBwW3jCe9LVTQk5ReEwiQil5NC4AXX2LUEg==
      hmac: hmac-sha512
    # optional additional updates to make based on simple matching rules
    # first match descending for IP wins. ranges and CIDRs should have same number of elements. these scripts don't do subnetting yet either. be careful.
    # <k8s native IP>, <mapping #1>, <mapping #2>, ...
    poolMap:
    - [ '192.168.123.201', '10.23.45.6', '56.43.21.9' ]
    - [ '192.168.123.202', '10.23.45.16' ]
    - [ '192.168.123.203', '', '56.43.21.19' ]
```

All servers get updated with all associated poolMap values of when a match for k8s native is found the k8s native IP. If no pool mapping is made, only the k8s native IP is updated.

## Monitoring

Deep Horizon should monitor the servers it is maintaining. Mechanism could be as simple as updating a dummy record, such as `_deep_horizon_canary.<cluster>.<delegated zone>`. If the record is found to no longer exist then Deep Horizon must scan IPs and update the server.

This allows for automatically updating upstream when Deep Horizon is initialized in a brown-deployment or if the upstream is an unreliable/stateless server. It is currently envisioned that the MM BP-DNS will be stateless.

Scan command:

```sh
kubectl get services --all-namespaces -o json | jq -c '[.items[] | select(.status.loadBalancer.ingress[]?.ip)]'
```

## Events

Events are provided by the [Shell-operator](https://github.com/flant/shell-operator) as JSON written to temporary files. The file name is provided to the script by the `BINDING_CONTEXT_PATH` environment variable.

Some example event objects:

```json
[{"binding":"onKubernetesEvent","resourceNamespace":"deephorizon","resourceKind":"ConfigMap","resourceName":"deephorizon-config","resourceEvent":"add"}]
```

```json
[{"binding":"onKubernetesEvent","resourceNamespace":"default","resourceKind":"Service","resourceName":"kubernetes","resourceEvent":"add"}]
```

## Nsupdate

Deep Horizon uses the `nsupdate` tool to actually perform dynamic DNS updates.

An example of the `nsupdate` command:

```sh
# update the A records
cat << EOF | nsupdate -d
server 192.168.123.99
zone k8s.agilestacks.vdc
key hmac-sha512:k8s_native 8YYclPBY4CnV/SlG4OZSSMrkR5KokkvpNbbJjhIV/JemLm7J2FOcziQawHt65KUj8S2AWtOW7KWmrpBGfswWrg==
update delete httpbin.default.cluster1.k8s.agilestacks.vdc
update add httpbin.default.cluster1.k8s.agilestacks.vdc 60 A 192.168.123.201
send
key hmac-sha512:corp_intranet nvKJxasg7hi40jijuqbywMwPz6JpLzTbo0VbQdPlyUWesfkhujsjBwW3jCe9LVTQk5ReEwiQil5NC4AXX2LUEg==
update delete httpbin.default.cluster1.k8s.agilestacks.vdc
update add httpbin.default.cluster1.k8s.agilestacks.vdc 60 A 10.23.45.6
send
quit
EOF

# update the canary TXT record
cat << EOF | nsupdate -d
server 192.168.123.99
zone k8s.agilestacks.vdc
key hmac-sha512:k8s_native 8YYclPBY4CnV/SlG4OZSSMrkR5KokkvpNbbJjhIV/JemLm7J2FOcziQawHt65KUj8S2AWtOW7KWmrpBGfswWrg==
update delete _deephorizon_canary.cluster1.k8s.agilestacks.vdc.
update add _deephorizon_canary.cluster1.k8s.agilestacks.vdc. 60 IN TXT "ok"
send
key hmac-sha512:corp_intranet nvKJxasg7hi40jijuqbywMwPz6JpLzTbo0VbQdPlyUWesfkhujsjBwW3jCe9LVTQk5ReEwiQil5NC4AXX2LUEg==
update delete _deephorizon_canary.cluster1.k8s.agilestacks.vdc.
update add _deephorizon_canary.cluster1.k8s.agilestacks.vdc. 60 IN TXT "ok"
send
quit
EOF

# check on the canary
dig @192.168.123.99 -t txt _deephorizon_canary.cluster1.k8s.agilestacks.vdc. +short
```
