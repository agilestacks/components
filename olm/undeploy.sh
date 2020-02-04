#!/bin/sh
kubectl --context="$DOMAIN_NAME" delete -f templates/olm.yaml
