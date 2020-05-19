# external-dns

Integration of Istio and External DNS. Why we need this? A very simple: there is a circular dependency between `external-dns` and `istio`. External-dns must know about istio in order to listen it's Gateway custom resources. Istio must also know about external-dns to provision routable DNS record for it'self. We resolve this circular dependency from: Istio knows about External DNS. External-dns doesn't know anything about istio. So, istio will patch external-dns deployment to advertise itself

## Trigger

Executed if:

* Environment variable `HUB_PROVIDES` contains `external-dns`

## File structure

* `Makefile` - provisioning driver
* `patch.jsonnet` - creates smart patch file for `external-dns` deployment. It will try to find a container named `external-dns` and lookup if arguments have `--source=istio` or `--istio-gateway=NAMESPACE/SERVICE` arguments. If missing then `kubectl` patch document will be created

## Input variables

* `EXTERNALDNS_NAMESPACE` - namespace for external dns
* `EXTERNALDNS_DEPL` - name of the Deployment resource to patch. Identified by `app.kubernetes.io/name=external-dns` label
* `ISTIO_NAMESPACE` - namespace for istio
* `ISTIO_GW_SVC` - name of the Istio Gateway service. Identifid by `istio=ingressgateway` label
