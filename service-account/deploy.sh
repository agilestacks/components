#!/bin/bash
HUB=${HUB:-hub}
echo "$ROLE" > role.yaml
kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" create serviceaccount "$SA"
if [ "$CLUSTER_ROLE" = "true" ]; then
  kubectl --context="$DOMAIN_NAME" apply -f role.yaml
  kubectl --context="$DOMAIN_NAME" create clusterrolebinding "$SA"-cluster-role-binding --clusterrole "$SA"-role --serviceaccount="$NAMESPACE":"$SA"
else
  kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" apply -f role.yaml
  kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" create rolebinding "$SA"-role-binding --role "$SA"-role --serviceaccount="$NAMESPACE":"$SA"
fi
SECRET=$(kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" \
  get serviceaccount "$SA" -o json | jq -r '.secrets[] | select(.name | contains("token")).name')
TOKEN=$(kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" \
  get secret "$SECRET" -o json | jq -r '.data.token')
TOKEN=$(openssl enc -base64 -d -A <<< "$TOKEN")
echo
echo Outputs:
echo
echo sa_token = "$TOKEN" | $HUB util otp
echo
