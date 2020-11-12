#!/bin/sh -x
kubectl --context="$DOMAIN_NAME" delete -f templates/olm.yaml
exit 0
