# External DNS

External DNS is a Kubernetes controller which watches Ingress and Service events in order to create new DNS records behind the scenes.
It will watch `Ingress.spec.host` or special `Service.annotations`. When an `external-ip` is set on a service,  external-dns goes to work creating records in its configured back-end.

https://github.com/kubernetes-incubator/external-dns

###DEPRECATED
This expects 2 parameters to be supplied via a PET or some other mechhanism.  It needs the customer/cloud-account aws credentials in order to spin up domains in the appropriate account. 

* `component.external-dns.accessKeyId` 
* `component.external-dns.secretAccessKey`
