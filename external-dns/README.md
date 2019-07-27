# ExternalDNS

[ExternalDNS](https://github.com/kubernetes-incubator/external-dns) synchronizes exposed Kubernetes Services and Ingresses with DNS providers.

## Limitations

Supports only [RFC2136](https://github.com/kubernetes-incubator/external-dns/blob/master/docs/tutorials/rfc2136.md) at this time. Does not know how to update Services with the `external-dns.alpha.kubernetes.io/hostname` annotation.

RFC2136 requires [TSIG](https://en.wikipedia.org/wiki/TSIG) to be enabled and configured on the target BIND service.

## Parameters

| Parameter | Default | Description  |
|:----------|---------|-----|
| `component.external-dns.provider` | `rfc2136` | the type of DNS service provider to use |
| `component.external-dns.rfc2136.host` | <empty> | IP of DNS (BIND) server to talk to |
| `component.external-dns.rfc2136.port` | 53 | port of the DNS server |
| `component.external-dns.rfc2136.tsig-secret` | <empty> | contents of your TSIG key for updating BIND |
| `component.external-dns.rfc2136.tsig-keyname` | <empty> | the name of your TSIG key |

## Supported verbs

* `deploy` - install ExternalDNS manifests via `kubectl`
* `undeploy` - delete ExternalDNS manifests via `kubectl`
