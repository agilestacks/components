# kubectl -n automation-hub run -ti --rm vault-shell --image=vault:1.2.3 /bin/sh
# vault operator migrate -config etcd-to-s3.hcl

storage_source "etcd" {
    address = "http://etcd-client.automation-hub.svc.cluster.local:2379"
    etcd_api = "v3"
}

storage_destination "s3" {
    region = "us-east-2"
    bucket = "vault-storage.superhub.io"
    path = "vault"
}
