# Traefik

[Traefik](https://traefik.io) is The Cloud Native Edge Router.

A reverse proxy / load balancer that's easy, dynamic, automatic, fast, full-featured, open source, production proven, provides metrics, and integrates with every major cluster technology.

### Multiple ingress controllers

Traefik by default process all ingress objects in all namespaces that have no `kubernetes.io/ingress.class` annotations or value of the annotation is `traefik`.

In case you'd like to run multiple ingress controllers: multiple Traefik instances or Traefik alongside with Nginx, for example, then you could customize the default behavior via following parameters:

```yaml
parameters:
- name: component.traefik.kubernetes.namespaces
  value: '[]'
- name: component.traefik.kubernetes.labelSelector
  empty: allow
- name: component.traefik.kubernetes.ingressClass
  empty: allow
```

That would match to Traefik [Kubernetes config](https://docs.traefik.io/configuration/backends/kubernetes/):

```
# Array of namespaces to watch.
#
# Optional
# Default: all namespaces (empty array).
#
# namespaces = ["default", "production"]

# Ingress label selector to filter Ingress objects that should be processed.
#
# Optional
# Default: empty (process all Ingresses)
#
# labelselector = "A and not B"

# Value of `kubernetes.io/ingress.class` annotation that identifies Ingress objects to be processed.
# If the parameter is non-empty, only Ingresses containing an annotation with the same value are processed.
# Otherwise, Ingresses missing the annotation, having an empty value, or the value `traefik` are processed.
#
# Optional
# Default: empty
#
# ingressClass = "traefik-internal"
```

Then, you could have two Traefik-s in the following setup:

```yaml
components:
- name: traefik
  source:
    dir: components/traefik
- name: public-ingress
  source:
    dir: components/traefik

lifecycle
  order:
  - public-ingress
  - traefik  # internal ingress shadows public-ingress
             # component.ingress.* outputs

parameters:
- component: traefik
  name: component.traefik.kubernetes.namespaces
  value: '["default", "kube-public", kube-system", "ingress", "dex", "automation-hub"]'
  
- component: public-ingress
  name: component.traefik.kubernetes.kubeconfigContext
  value: ${stack-k8s-aws:dns.domain}
- component: public-ingress
  name: component.traefik.kubernetes.namespaces
  value: '["applications"]'
- component: public-ingress
  name: dns.name
  value: apps
- component: public-ingress
  name: dns.domain
  value: domain.com
- component: public-ingress
  name: component.acm.certificateArn
  value: ...
```

Or, switching ingress controller on `metadata.annotations.kubernetes.io/ingress.class: my-public-apps`:

```yaml
parameters:
- component: public-ingress
  name: component.ingress.ingressClass
  value: my-public-apps
```

Then every ingress that goes into `applications` namespace (or annotated with `kubernetes.io/ingress.class: my-public-apps`) is controlled by `public-ingress` Traefik. 

Even though you might not use Hub component model for your services initially - by using Helm or `kubectl` directly, in case you do then you may want to distinguish multiple `component.ingress.*` outputs. There are two options:

1. The exact output is referenced in `hub-component.yaml` parameter `value:` via a prefix `${public-ingress:component.ingress.fqdn}`. This introduces tight coupling.
2. A mapping is setup at `params.yaml` level:
```
parameters:
- name: component.public-ingress.fqdn
  value: ${public-ingress:component.ingress.fqdn}
  kind: link
```

In future Hub CLI will allow a simplified shadowing / remapping of duplicated outputs.
