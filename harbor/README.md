# Harbor Docker Registry

Current component deploys Harbor private docker registry [link](https://harbor.io)

## Requirements

Harbor deployment has been primarilly driven byhelm chart [link](TBD). However for correct work of docker registry we need to satisfy following requirements

1. TLS - docker nativelly support TLS. So harbor ingress must have a valid TLS certificate or docker daemon must be configured to accept insecure docker registry
2. Storage - harbor natively support several storage backends for registry

Please refer to the deployment **flavors** for supported variations

## Flavors

Current component supports number of deployment variations

- `aws`: deploys harbor to AWS d
- `metal`: private data center or bare metal kubernetes deployment support

### AWS

Enabled if `cloud.kind: aws` Supports following options

1. TLS options (configured via `component.tls.kind`)
- `letsencrypt` - if enabled then Harbor will be installed behind Traefik ingress controller
- `acm` (recommended) - if enabled then Harbor will exposed via ELB with TLS offload


2. Storage backend (configured via `component.harbor.storage`)
- `local` - if enabled then Harbor will use EBS baked storage (dynamically provisioned)
- `s3` (recommended) - if enabled then images will be stored in s3 (transitive dependency on `s3` component)
- `minio` (recommended) - if enabled then images will be stored in minio (transitive dependency on `minio` component)

## TLS

TLS is a must for Harbor (or any docker registry). Therefore component supports two options `letsencrypt` and `acm` specified by parameter `component.tls.kind`. So, component expects the following to be provided:
```yaml
---
parameters:
- name: component.tls.kind
  value: acm
  # or value: letsencrypt
```


### metal

Enabled if `cloud.kind: metal`. Supports following options

1. TLS options (configured via `component.tls.kind`). Ingress controller must pass `component.ingress.staticIp`
- `letsencrypt` - if enabled then Harbor will be installed behind Traefik ingress controller

2. Storage backend (configured via `component.harbor.storage`)
- `local` - if enabled then harbor will be using `hostPath` persistent volumes (must be preprovisioned by cluster amin)
- `minio` (recommended) - if enabled then images will be stored in minio (transitive dependency on `minio` component)

