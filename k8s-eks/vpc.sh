#!/bin/bash -xe

#export KUBECONFIG=kubeconfig
kubectl_run="kubectl --context=$DOMAIN_NAME run --rm -ti k8s-eks-shell --image busybox --restart=Never -- sh -c"
meta='wget -qO - http://169.254.169.254/latest/meta-data'
macs="$meta/network/interfaces/macs"

vpc=$($kubectl_run "$macs/\$($macs | head -1)vpc-id")
cdr=$($kubectl_run "$macs/\$($macs | head -1)vpc-ipv4-cidr-block")

set +x

echo Outputs:
echo vpc = $vpc
echo vpc_cidr_block = $cdr
echo
