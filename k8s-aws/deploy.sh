#!/bin/bash -xe

#export KUBECONFIG=kubeconfig
kubectl_run="kubectl --context=$DOMAIN_NAME run --rm -ti k8s-aws-shell --image busybox --restart=Never --"
meta='wget -qO - http://169.254.169.254/latest/meta-data'

mac=$($kubectl_run $meta/network/interfaces/macs)
vpc=$($kubectl_run $meta/network/interfaces/macs/$mac/vpc-id)
cdr=$($kubectl_run $meta/network/interfaces/macs/$mac/vpc-ipv4-cidr-block)

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
