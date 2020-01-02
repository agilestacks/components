# Examples

Current directory contains some useful **external-dns** component usage examples.

- `dns-entrypoint.yaml.template`: after successful `hub deploy` will render into ready to `kubectl apply` file. This is an example how to define DNS as a custom resource
- `ingress.yaml`: example of kube-dashboard. Warning!!! Bypasses dex auth. Use with caution
