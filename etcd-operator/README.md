# ETCD Operator Hub Component

ETCD Operator Hub Component as Kubernetes Pod installed from kubernetes chart stable/etcd-operator.

Needs:
1) kubernetes secret with aws config, cluster won't start without it if you use backup.enabled=true:
<pre><code>
[profile default]
region = us-east-2
</code></pre>
2) S3 bucket for storing backups, backup sidecar will crash until it's created.

Uses:
https://github.com/kubernetes/charts/tree/master/stable/etcd-operator
https://github.com/coreos/etcd-operator

