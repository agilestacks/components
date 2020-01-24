# Manifest for Istio in Kubeflow

- `install` dir contains the manifest to install Istio
- kf-istio-resources.yaml has
  - Gateway for routing
  - VirtualService for Grafana
  - ServiceEntry and VirtualService for egress traffic

## Customized for Agile STacks

- Deleted cluster roles. As we will reuse istio installed by the `istio` component.
