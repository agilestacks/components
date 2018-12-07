# Minio

[Minio](https://github.com/minio/minio) is a storage server, compatible with with Amazon S3 cloud storage service. It is best suited for storing unstructured data such as photos, videos, log files, backups and container / VM images. Size of an object can range from a few KBs to a maximum of 5TB.

Minio server is light enough to be bundled with the application stack, similar to NodeJS, Redis and MySQL.

## Usage

Current component installs minio with helm chart and then creates an alias for minio client with default bucket.

## Prerequisites

Current component requires following prerequisites to be available:

* Kubernetes cluster
* Ingress controller
* SSL certificate (optional)
* Tiller
* Minio client

```bash
go get -d github.com/minio/mc
cd ${GOPATH}/src/github.com/minio/mc
make
mv mc ~/bin/
```

## Parameters

Below you will find a list of essential parameters. All parameters can be found in [hub-component.yaml](https://github.com/agilestacks/components/blob/master/minio/hub-component.yaml)

| Parameter | Default | Description  |
|:----------|---------|-----|
| `component.minio.name` | `minio` | Minio component name |
| `component.minio.accessKey` | <empty> | Access key for minio server. Stored in the secret with identified by component name. Random if empty |
| `component.minio.secretKey` | <empty> | Secret key for minio server. Stored in the secret with identified by component name. Random if empty |
| `component.minio.volumeType` | `gp2` | Type of minio volume for dynamic provisioner |
| `component.minio.storageSize` | `20Gi` | Size for PV to be created |
| `component.minio.bucket.name` | `default` | Default bucket to be created |
| `component.minio.bucket.policy` | `public` | Default bucket ACL |

## Outputs

| Parameter | Description  |
|:----------|-----|
| `component.minio.endpoint` | Minio endpoint available for reference inside same cluster |
| `component.minio.endpoint.ingress` | Minio endpoint for reference outside cluster |
| `component.minio.secret.name` | Name of the secret where access and secret key to e stored |
| `component.minio.secret.accessKeyRef` | Key reference in the secret |
| `component.minio.secret.accessKeyRef` | Key reference in the secret |

## Supported verbs

* `deploy` - install minio server with Helm chart
* `undeploy` - reverse `deploy` verb
* `configure` - create an alias for minio client
* `unconfigure` - reverse `configure` verb

## Minio events 

Currently component supports `postgresql`, `nats` and `redis` as a backend to publish minio bucket events.
