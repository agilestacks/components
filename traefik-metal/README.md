# Traefik

This is the pure-metal (outpost, isolated, etc) version of Traefik. It has no reliance on terraform or any cloud services.  It expects external-dns or deephorizon to exist.  It also expects to use a deployment from automation-tasks on the destination cluster, and to not be deployed from the ASI automation-hub cluster.

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
# bind internal Traefik to a standard list of namespaces
- component: traefik
  name: component.traefik.kubernetes.namespaces
  value: '["default", "kube-public", kube-system", "ingress", "dex", "automation-hub"]'

# for public Traefik we want to install it into
# Kubernetes context named after DNS domain
- component: public-ingress
  name: component.traefik.kubernetes.kubeconfigContext
  value: ${stack-k8s-aws:dns.domain}
  kind: link
# bind public Traefik to a different namespace
- component: public-ingress
  name: component.traefik.kubernetes.namespaces
  value: '["applications"]'
# give it some arbitrary name
- component: public-ingress
  name: dns.name
  value: cool-apps
# and once again (for Helm and Kubernetes resources)
- component: public-ingress
  name: component.ingress.name
  value: apps
# and the domain to root into
- component: public-ingress
  name: dns.domain
  value: cool-apps.com
# ACM TLS certificate ARN
- component: public-ingress
  name: component.acm.certificateArn
  value: arn:aws:acm:...

# optionally
# these prefixes does not conflict with default Traefik prefixes
# you can have app/apps here too
- component: public-ingress
  name: component.ingress
  parameters:
  - name: urlPrefix
    value: pub
# if you make it equal to ssoUrlPrefix (apps) then it will
# be protected by Dex
  - name: ssoUrlPrefix
    value: pubs

# dashboard http basic auth if not protected by Dex
- component: public-ingress
  name: component.ingress.dashboard.auth
  # admin/secret
  value: '{basic: { admin: "$apr1$11TLkGsi$yfpfzk0inznhPal5OE3Fl/"}}'
```

Traefik will serve under `*.pub/s.cool-apps.com`.

Or, switching ingress controller on `metadata.annotations.kubernetes.io/ingress.class: my-public-apps`:

```yaml
parameters:
- component: public-ingress
  name: component.traefik.kubernetes.ingressClass
  value: my-public-apps
```

Every ingress that goes into `applications` namespace (or annotated with `kubernetes.io/ingress.class: my-public-apps`) is controlled by `public-ingress` Traefik. You may also omit namespace parameters if you choose to switch on ingress class.

### No Traefik Dashboard

When `component.traefik.kubernetes.namespaces` option is used you may get 404 HTTP error visiting Traefik Dashboard URL. The problem is that public ingress Traefik might be installed in the namespace is does not _oversee_. By default Traefik installs into `ingress` namespace that is managed by default Traefik. Public ingress Traefik cannot see it’s own ingress object / route. There are two options:
1. In case you segregate controllers both on ingress class and namespace, then add `ingress` namespace to `component.traefik.kubernetes.namespaces` of `public-ingress`. It won’t conflict with default Traefik because of `ingressClass`.
2. Otherwise install public ingress into some of the namespaces it oversees or in it’s own namespace. The parameter controlling namespace to install into is `component.ingress.namespace`.

### Hub parameters

Even though you might not use Hub component model for your services initially - using Helm or `kubectl` directly instead, in case you do then you may want to distinguish duplicates of `component.ingress.*` outputs. If deployment order - last component outputs wins - favor your configuration, then you don't need to do anything. Alternatively, there are two options:

1. The exact output is referenced in `hub-component.yaml` parameter `value:` via a prefix `${public-ingress:component.ingress.fqdn}`. This introduces tight coupling.
2. A mapping is setup at `params.yaml` level:
```
parameters:
- name: component.public-ingress.fqdn
  value: ${public-ingress:component.ingress.fqdn}
  kind: link
- name: component.ingress.ssoFqdn
  component: kube-dashboard
  value: ${public-ingress:component.ingress.fqdn}
  kind: link
```

Traefik component also emit `component.ingress.kubernetes.ingressClass` output for use by component's ingress objects. As the value might be empty, you need to double-quote `""` it in templates, ie. `kubernetes.io/ingress.class: "${component.ingress.kubernetes.ingressClass}"`.

In future Hub CLI will allow a simplified shadowing / remapping of duplicated outputs.
