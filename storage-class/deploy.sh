#!/bin/sh -x
KIND=$CLOUD_KIND
case $HUB_PROVIDES in
    *aws-ebs-csi-driver*)
        KIND=aws-ebs-csi-driver
        ;;
esac
if test ! -f $KIND.yaml; then exit 0; fi
cat $KIND.yaml
exec kubectl --context="$DOMAIN_NAME" apply -f $KIND.yaml
