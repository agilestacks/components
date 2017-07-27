# ETCD Operator Hub Component

[etcd Operator](https://github.com/coreos/etcd-operator) Hub Component as Kubernetes deployment installed from kubernetes chart [stable/etcd-operator](https://github.com/kubernetes/charts/tree/master/stable/etcd-operator).

## Needs:
1) kubernetes secret with aws config, cluster won't start without it if you use `backup.enabled=true`:
```
[profile default]
region = us-east-2
```

2) S3 bucket for storing backups, backup sidecar will crash until it's created.
