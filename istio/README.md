# Istio 

Current component installs istio service mesh

We maintain multiple versions of the **istio**. Perhaps in the future each version will deserve a separate component to give a separate lifecycle and maturity for each version.


## Component structure

Istio has been provisioned by the
* Terraform (DNS name)
* Helm chart (actual istio resources)

### Terraform

Current component will use a terraform to provision a DNS name. In the future terraform will be placed with [ExternalDNS](https://github.com/agilestacks/components/tree/master/external-dns).

The terrraform has been placed in the directory that has bene selected by `cloud.kind` parameter.


### Helm chart

Helm chart configuratio defaults to `values.yaml.template` and has been overriden by `values-${component.istio.version.release}.yaml.template`

We provision two helm charts from https://storage.googleapis.com/istio-release/releases/

* `istio-init` - CRDs and other prerequisites
* `istio` - actual istio installation. Current helm chart has a tons of other chart dependencies. We will need to replace it with our components.

## Dependencies

### Optional Compnents

Current component works in conjunction with:
* [ExternalDNS](https://github.com/agilestacks/components/tree/master/external-dns) - It will recognize Gateway resources managed by istio and will automatically create a DNS record

## Input Parameters

| Parameter                          | Default Value  | Brief                                                  |
|------------------------------------|----------------|--------------------------------------------------------|
| cloud.kind                         | aws            | One of [aws,azure,gcp,hybrid]                          |
| component.istio.version.release    | v1.4.3         | Release version of the helm chart                      |
| componnet.istio.namespace          | istio-system   | Namespace for istio                                    |
| component.istio.tracing.enabled    | false          |                                                        |
| component.istio.prometheus.enabled | true           | Warning! Installs it's own prometheus (technical dept) |
| component.istio.grafana.enabled    | false          |                                                        |
| component.istio.ingressGateway     | ingressgateway | Name used in Gateway resoruce (`spec.selector.istio`)  |


##  Ouptut Parameters

| Parameter                          | Brief                                                                       |
|------------------------------------|-----------------------------------------------------------------------------|
| component.istio.kiali.url          | URL of the kiali (for Control Plane)                                        |
| component.istio.ingressGateway     | Used in Gateway resource to link with current istio (`spec.selector.istio`) |

