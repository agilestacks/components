# Vault Hub Component

This directory contains a Hub component and helm chart to deploy a Vault server.

## Prerequisites Details

* Kubernetes 1.5
* [etcd component](https://github.com/agilestacks/components/tree/master/etcd) as a backend storage (uses storage address composed from etcd component vars)

## Chart Details

This chart will do the following:

* Implement a Vault deployment

Please note that a backend service for Vault (for example, Consul) must
be deployed beforehand and configured with the `vault` option. YAML provided
under this option will be converted to JSON for the final vault `config.json`
file.

> See https://www.vaultproject.io/docs/configuration/ for more information.

## Installing the Chart

To install the chart, use the following, this backs vault with a Consul cluster:

```console
$ helm install vault --name vault-service --namespace vault
```

An alternative example using the Amazon S3 backend can be specified using:

```
vault:
  storage:
    s3:
      access_key: "AWS-ACCESS-KEY"
      secret_key: "AWS-SECRET-KEY"
      bucket: "AWS-BUCKET"
      region: "us-east-2"
```

## Configuration

The following tables lists the configurable parameters of the vault component and their default values.

|       Parameter         |           Description               |                         Default                     |
|-------------------------|-------------------------------------|-----------------------------------------------------|
| `component.vault.image.pullPolicy`      | Container pull policy               | `IfNotPresent`                                      |
| `component.vault.image.repository`      | Container image to use              | `vault`                                             |
| `component.vault.version`             | Container image tag to deploy       | `0.7.3`                                             |
| `component.vault.name`    | Vault service name to use           | `vault-service`                                                   |
| `component.vault.namespace` | k8s namespace to install component into         | `vault`                                           |
| `component.vault.ipaddress`             | Vault server IP address             | `0.0.0.0`                                         |
| `component.vault.port`    | Vault server and service port to use                   | `8200`                                       |
| `component.vault.ingress.enabled`       | Ingress for Vault      | `false`                                                        |
| `component.vault.tls.disabled`          | Specifies if TLS will be disabled        | `false`                                      |
| `vault`                 | Vault configuration, currently only storage backend      | `etcd`                                       |
| `component.vault.storage.url`           | etcd url to use for storage backend      | `composed from etcd vars`                                     |
| `component.vault.etcd.api`              | etcd API version to use            | `v3`                                                |
| `component.vault.replicaCount`          | k8s replicas                        | `1`                                                 |
| `component.vault.resources.limits.memory` | Container requested memory        | `128Mi`                                             |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

## Using Vault

Once the Vault pod is ready, it can be accessed using a `kubectl
port-forward`:

```console
$ kubectl port-forward vault-pod 8200
$ export VAULT_ADDR=http://127.0.0.1:8200
$ vault status
```

Or using local container:
```console
$ kubectl run --rm -i --tty --env VAULT_ADDR=http://vault-service-vault.vault.svc.cluster.local:8200 vault-test --image=vault --restart=Never -n default -- /bin/sh -c "vault status"
```
