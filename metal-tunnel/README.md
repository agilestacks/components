# metal-tunnel

This component is intended to be executed along with the constellation of automation-hub components. It creates an SSH over HTTP tunnel that is initiated by a remote client.  It is exposed to the internet via its own nlb, or equivalent in other clouds,  using the Service of type LoadBalancer. 

This exposes port 80 to the internet so that remote tunnel clients may connect from their NAT'd and firewalled environments. 

It exposes ports 443 and 6443 to the k8s cluster so that the tunneled services may be accessed by local k8s pods. 


