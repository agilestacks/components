#!/bin/bash -e

ARGS=$*
while [ "$1" != "" ]; do
  case $1 in
    -n | --namespace ) 
      shift
      NAMESPACE="$1"
      ;;                
  esac
  shift
done

# shellcheck disable=SC2086
if ! kubectl $ARGS get namespace "$NAMESPACE" > /dev/null 2>&1; then
  exit
fi

echo -n "Dropping finalizers: "
kubectl $ARGS get namespace "$NAMESPACE" -o json \
  | jq '. | del(.spec.finalizers)' \
  | kubectl $ARGS replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f - >/dev/null
echo "Done"
echo -n "Deleting $NAMESPACE: "
# shellcheck disable=SC2086
kubectl $ARGS delete namespace "$NAMESPACE"
