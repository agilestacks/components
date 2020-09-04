# Istio Ingress Gateway

Current component will use a Helm chart to deploy an Istio Ingress Gateway

## Parameters

Input parameters:
* `hub.componentName` - Name of the istio ingress gateway
* `component.istio.namespace` - Namespace of the istio (defaults to: `istio-system`)
* `component.istio.ingressGateway.type` - reserved for future variability (defaults to: `sds` )

Output parameters:
* `component.istio.ingressGateway` - Name of istio gateeway

## Implementation Specifics

Helm chart downloaded from istio repo: https://storage.googleapis.com/istio-release/releases/$(ISTIO_VERSION)/charts/

We use a helm chart `gateways`, which is a dependency of the helm chart `istio`.

Values files has been taken with with precedence to the later:
1. Global values: Taken from `istio/values.yaml` only `global`; rest has been ignored
2. Ingress gateway default values: Taken from `istio/charts/gateways/values.yaml` only `istio-ingressgateway` (renamed to `hub.componentName`); rest has been ignored
3. Component values from: `values.yaml.template`
