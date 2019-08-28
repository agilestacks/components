# External DNS

External DNS is a Kubernetes controller which watches Ingress and Service events in order to create new DNS records behind the scenes.
It will watch `Ingress.spec.host` or special `Service.annotations`. When an `external-ip` is set on a service,  external-dns goes to work creating records in its configured back-end.

https://github.com/kubernetes-incubator/external-dns
