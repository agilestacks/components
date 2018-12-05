#!/bin/bash -xe

#export KUBECONFIG=kubeconfig
# this will break if k8s-eks-shell is occupied
kubectl_run="kubectl --context=$DOMAIN_NAME run --rm -ti k8s-eks-shell --image busybox --restart=Never -- sh -c"
meta='wget -qO - http://169.254.169.254/latest/meta-data'
macs="$meta/network/interfaces/macs"

zone=$($kubectl_run "$meta/placement/availability-zone" | sed -e 's/pod "k8s-eks-shell" deleted//')
region=$(echo $zone | sed -e 's/.$//')
sleep 1
vpc=$($kubectl_run "$macs/\$($macs | head -1)vpc-id" | sed -e 's/pod "k8s-eks-shell" deleted//')
sleep 1
cidr=$($kubectl_run "$macs/\$($macs | head -1)vpc-ipv4-cidr-block" | sed -e 's/pod "k8s-eks-shell" deleted//')
sleep 1
subnet=$($kubectl_run "$macs/\$($macs | head -1)subnet-id" | sed -e 's/pod "k8s-eks-shell" deleted//')
sleep 1
sg=$($kubectl_run "$macs/\$($macs | head -1)security-group-ids | head -1" | sed -e 's/pod "k8s-eks-shell" deleted//')

set +x

echo Outputs:
echo region = $region
echo zone = $zone
echo vpc = $vpc
echo vpc_cidr_block = $cidr
echo worker_subnet_id = $subnet
echo worker_sg_id = $sg
echo
