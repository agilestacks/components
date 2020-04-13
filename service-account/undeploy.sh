#!/bin/sh
echo "$ROLE" > role.yaml
if [ "$CLUSTER_ROLE" = "true" ]; then
  kubectl --context="$DOMAIN_NAME" delete clusterrolebinding "$SA"-cluster-role-binding
  kubectl --context="$DOMAIN_NAME" delete -f role.yaml
else
  kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" delete rolebinding "$SA"-role-binding
  kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" delete -f role.yaml
fi
kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" delete serviceaccount "$SA"
