#!/bin/sh
echo "$ROLE" > role.yaml
kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" create serviceaccount "$SA"
kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" apply -f role.yaml
kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" create rolebinding "$SA"-role-binding --role "$SA"-role --serviceaccount="$NAMESPACE":"$SA"
SECRET=$(kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" \
  get serviceaccount "$SA" -o json | jq -r '.secrets[] | select(.name | contains("token")).name')
TOKEN=$(kubectl --context="$DOMAIN_NAME" -n "$NAMESPACE" \
  get secret "$SECRET" -o json | jq -r '.data.token')
echo
echo Outputs:
echo
echo sa_token = "$TOKEN"
echo
