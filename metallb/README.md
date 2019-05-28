# MetalLB

[MetalLB](https://metallb.universe.tf) is a load-balancer implementation for bare metal Kubernetes clusters, using standard routing protocols.

## Limitations

Presently this component supports **only** [MetalLB's layer-2 mode](https://metallb.universe.tf/concepts/layer2/) which provides an ARP-based fail-over mechanism for virtual IPs. This is **not** true "load balancing" because all connections to the load balancer virtual IPs will be funneled to a single node, not spread across many. Actual load balancing is achievable by using [MetalLB's BGP mode](https://metallb.universe.tf/concepts/bgp/) which requires integrating MetalLB network BGP routers *and* configuring an [ECMP](https://en.wikipedia.org/wiki/Equal-cost_multi-path_routing) routing strategy.

While it does not provide true load balancing, the layer-2 mode is still very desireable because it is dead simple to set up and portable across networks since it only requires layer-2 connectivity to work.

> *Note:* MetalLB does **not** load balance the Kubernetes API Server endpoint. There are some [ideas for addressing this problem](https://github.com/danderson/metallb/issues/168) but not yet attempted. Metal Manager currently requires either a separate external load balancer, or it can set up [keepalived](https://www.keepalived.org/) on master nodes to address the problem.

MetalLB supports configuring [multiple address pools](https://metallb.universe.tf/configuration/#advanced-address-pool-configuration) but this component only supports configuring a single address pool.

## Parameters

| Parameter | Default | Description  |
|:----------|---------|-----|
| `component.metallb.namespace` | `metallb-system` | kubernetes namespace where MetalLB will be installed |
| `component.metallb.controllerImage` | `metallb/controller` | container image to use for the MetalLB "controller" |
| `ccomponent.metallb.speakerImage` | `metallb/speaker` | container image to use for the MetalLB "speakers" |
| `component.metallb.version` | `v0.7.3` | version of MetalLB to deploy |
| `component.metallb.addressPoolName` | `default` | name of the address pool being defined |
| `component.metallb.addressPool` | <empty> | list of addresses and ranges to be managed by MetalLB as VIPs |

## Supported verbs

* `deploy` - install MetalLB manifests via `kubectl`
* `undeploy` - delete MetalLB manifests via `kubectl`
