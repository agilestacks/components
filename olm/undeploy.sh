#!/bin/sh
kubectl --context="$DOMAIN_NAME" delete -f templates/olm.yaml
kubectl --context="$DOMAIN_NAME" delete -f templates/crds.yaml
