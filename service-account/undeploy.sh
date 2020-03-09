#!/bin/sh
echo "$ROLE" > role.yaml
kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" delete rolebinding "$SA"-role-binding
kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" delete -f role.yaml
kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" delete serviceaccount "$SA"
