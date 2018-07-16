#!/bin/bash -xe

#export KUBECONFIG=kubeconfig
kubectl_run="kubectl --context=$DOMAIN_NAME run --rm -ti k8s-aws-shell --image busybox --restart=Never -- sh -c"
meta='wget -qO - http://169.254.169.254/latest/meta-data'
macs="$meta/network/interfaces/macs"

vpc=$($kubectl_run "$macs/\$($macs | head -1)vpc-id")
cidr=$($kubectl_run "$macs/\$($macs | head -1)vpc-ipv4-cidr-block")
subnet=$($kubectl_run "$macs/\$($macs | head -1)subnet-id")
sg=$($kubectl_run "$macs/\$($macs | head -1)security-group-ids | head -1")

name=$(echo $DOMAIN_NAME | cut -d. -f1)
domain=$(echo $DOMAIN_NAME | cut -d. -f2-)

set +x

echo Outputs:
echo dns_name = $name
echo dns_base_domain = $domain
echo vpc = $vpc
echo vpc_cidr_block = $cidr
echo worker_subnet_id = $subnet
echo worker_sg_id = $sg
echo
