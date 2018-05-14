#!/bin/bash -xe

#export KUBECONFIG=kubeconfig
kubectl_run="kubectl --context=$DOMAIN_NAME run --rm -ti k8s-aws-shell --image busybox --restart=Never -- sh -c"
meta='wget -qO - http://169.254.169.254/latest/meta-data'
macs="$meta/network/interfaces/macs"

vpc=$($kubectl_run "$macs/\$($macs)vpc-id")
cdr=$($kubectl_run "$macs/\$($macs)vpc-ipv4-cidr-block")

# ingress_fqdn=$(kubectl --namespace=ingress get svc traefik -o json |jq -r '.metadata.annotations["api.service.kubernetes.io/path"]')

name=$(echo $DOMAIN_NAME | cut -d. -f1)
domain=$(echo $DOMAIN_NAME | cut -d. -f2-)

set +x

echo Outputs:
echo dns_name = $name
echo dns_base_domain = $domain
echo vpc = $vpc
echo vpc_cidr_block = $cdr
echo
