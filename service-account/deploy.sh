#!/bin/bash -xe
HUB=${HUB:-hub}
kubectl="kubectl --context=$DOMAIN_NAME -n $NAMESPACE"
$kubectl create serviceaccount "$SA"
if test "$CLUSTER_ROLE" = true; then
  echo "$ROLE" | sed -e 's/: Role/: ClusterRole/' | $kubectl apply -f -
  $kubectl create clusterrolebinding "$SA"-cluster-role-binding --clusterrole "$SA"-role --serviceaccount="$NAMESPACE":"$SA" || true
else
  echo "$ROLE" | $kubectl apply -f -
  $kubectl create rolebinding "$SA"-role-binding --role "$SA"-role --serviceaccount="$NAMESPACE":"$SA" || true
fi
echo
echo Outputs:
set -o pipefail
$kubectl get serviceaccount "$SA" -o json |
  jq -r '.secrets[] | select(.name | contains("token")).name' |
  xargs $kubectl get secret -o json |
  jq -r '"sa_token = " + .data.token' |
  $HUB util otp
echo
