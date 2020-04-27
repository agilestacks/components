#!/bin/bash -x
kubectl="kubectl --context=$DOMAIN_NAME -n $NAMESPACE"
if test "$CLUSTER_ROLE" = true; then
  $kubectl delete clusterrolebinding "$SA"-cluster-role-binding
  echo "$ROLE" | sed -e 's/: Role/: ClusterRole/' | $kubectl delete -f -
else
  $kubectl delete rolebinding "$SA"-role-binding
  echo "$ROLE" | $kubectl delete -f -
fi
$kubectl delete serviceaccount "$SA"
exit 0
