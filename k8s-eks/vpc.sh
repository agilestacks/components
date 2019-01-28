#!/bin/bash -xe

#export KUBECONFIG=kubeconfig
# this will break if k8s-eks-shell is occupied
kubectl_run="kubectl --context=$DOMAIN_NAME run --rm -ti k8s-eks-shell --image busybox --restart=Never -- sh -c"
meta='wget -qO - http://169.254.169.254/latest/meta-data'
macs="$meta/network/interfaces/macs"

set +x

$kubectl_run "
mac=\$($macs | head -1)
echo Outputs:
echo region = \$($meta/placement/availability-zone | sed -e 's/.$//')
echo zone = \$($meta/placement/availability-zone)
echo vpc = \$($macs/\${mac}vpc-id)
echo vpc_cidr_block = \$($macs/\${mac}vpc-ipv4-cidr-block)
echo worker_subnet_id = \$($macs/\${mac}subnet-id)
echo worker_sg_id = \$($macs/\${mac}security-group-ids | head -1)
echo
"
