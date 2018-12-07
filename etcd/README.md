# ETCD Hub Component

etcd Hub Component (based on [etcd-operator](https://github.com/coreos/etcd-operator)) as Kubernetes deployment installed from kubernetes chart [stable/etcd-operator](https://github.com/kubernetes/charts/tree/master/stable/etcd-operator).

## Needs:
1) kubernetes secret with aws config and credentials, 
   cluster won't start without it if you enable periodic backups (set `backup.enabled=true`)
   or if you try to perform backup on demand:
```
[profile default]
region = us-east-2
```
```
[default]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

2) S3 bucket for storing backups, backup sidecar will crash until it's created.

## Configuration

The following tables lists the configurable parameters of the etcd-operator chart and their default values.

| Parameter                                         | Description                                                          | Default                                        |
| ------------------------------------------------- | -------------------------------------------------------------------- | ---------------------------------------------- |
| `replicaCount`                                    | Number of etcd-operator replicas to create (only 1 is supported)     | `1`                                            |
| `image.repository`                                | etcd-operator container image                                        | `quay.io/coreos/etcd-operator`                 |
| `image.tag`                                       | etcd-operator container image tag                                    | `v0.3.2`                                       |
| `image.pullPolicy`                                | etcd-operator container image pull policy                            | `IfNotPresent`                                 |
| `resources.limits.cpu`                            | CPU limit per etcd-operator pod                                      | `100m`                                         |
| `resources.limits.memory`                         | Memory limit per etcd-operator pod                                   | `128Mi`                                        |
| `resources.requests.cpu`                          | CPU request per etcd-operator pod                                    | `100m`                                         |
| `resources.requests.memory`                       | Memory request per etcd-operator pod                                 | `128Mi`                                        |
| `nodeSelector`                                    | node labels for etcd-operator pod assignment                         | `{}`                                           |
| `cluster.enabled`                                 | Whether to enable provisioning of an etcd-cluster                    | `false`                                        |
| `cluster.name`                                    | etcd cluster name                                                    | `etcd-cluster`                                 |
| `cluster.version`                                 | etcd cluster version                                                 | `v3.1.8`                                       |
| `cluster.size`                                    | etcd cluster size                                                    | `3`                                            |
| `cluster.backup.enabled`                          | Whether to create PV for cluster backups                             | `false`                                        |
| `cluster.backup.provisioner`                      | Which PV provisioner to use                                          | `kubernetes.io/gce-pd` (kubernetes.io/aws-ebs) |
| `cluster.backup.config.snapshotIntervalInSecond`  | etcd snapshot interval in seconds                                    | `30`                                           |
| `cluster.backup.config.maxSnapshot`               | maximum number of snapshots to keep                                  | `5`                                            |
| `cluster.backup.config.storageType`               | Type of storage to provision                                         | `PersistentVolume`                             |
| `cluster.backup.config.pv.volumeSizeInMB`         | size of backup PV                                                    | `512MB`                                        |
| `cluster.restore.enabled`                         | Whether to restore from PV                                           | `false`                                        |
| `cluster.restore.config.storageType`              | Type of storage to restore from                                      | `PersistentVolume`                             |
| `cluster.restore.config.backupClusterName`        | Name of cluster to restore from                                      | `etcd-cluster`                                 |
| `cluster.pod.antiAffinity`                        | Whether etcd cluster pods should have an antiAffinity                | `false`                                        |
| `cluster.pod.resources.limits.cpu`                | CPU limit per etcd cluster pod                                       | `100m`                                         |
| `cluster.pod.resources.limits.memory`             | Memory limit per etcd cluster pod                                    | `128Mi`                                        |
| `cluster.pod.resources.requests.cpu`              | CPU request per etcd cluster pod                                     | `100m`                                         |
| `cluster.pod.resources.requests.memory`           | Memory request per etcd cluster pod                                  | `128Mi`                                        |
| `cluster.pod.nodeSelector`                        | node labels for etcd cluster pod assignment                          | `{}`                                           |
| `rbac.install`                                    | install required rbac service account, roles and rolebindings        | `false`                                         |
| `rbac.apiVersion`                                 | rbac api version `v1alpha1|v1beta1`                                  | `v1beta1`                                      |


## RBAC
By default the chart will not install the recommended RBAC roles and rolebindings.

To determine if your cluster supports this running the following:

```console
$ kubectl api-versions | grep rbac
```

You also need to have the following parameter on the api server. See the following document for how to enable [RBAC](https://kubernetes.io/docs/admin/authorization/rbac/)

```
--authorization-mode=RBAC
```

If the output contains "beta" or both "alpha" and "beta" you can may install with enabling the creating of rbac resources (see below).

### Enable RBAC role/rolebinding creation

To enable the creation of RBAC resources (On clusters with RBAC). Do the following:

```console
$ helm install --name my-release . --set rbac.install=true
```

### Changing RBAC manifest apiVersion

By default the RBAC resources are generated with the "v1beta1" apiVersion. To use "v1alpha1" do the following:

```console
$ helm install --name my-release . --set rbac.install=true,rbac.apiVersion=v1alpha1
```
