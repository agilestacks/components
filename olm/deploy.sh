#!/bin/sh
kubectl --context="$DOMAIN_NAME" apply -f templates/namespaces.yaml
kubectl --context="$DOMAIN_NAME" apply -f templates/crds.yaml
kubectl --context="$DOMAIN_NAME" apply -f templates/olm.yaml
