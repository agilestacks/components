#!/bin/bash -e

NAMESPACE="$1"
shift

KUBECTL="kubectl --context=$HUB_DOMAIN_NAME"
KUBECTL_DELETE="$KUBECTL -n "$NAMESPACE" delete $*"

UNWANTED="namespace events endpoints bindings "
UNWANTED="localsubjectaccessreviews.authorization.k8s.io $UNWANTED"

echo "Cleaning up dangling resources in $NAMESPACE namespace..."

if test -z "$(which parallel)"; then
  echo "Warning: parallel cannot be found"
  echo "parallel will make clean up faster"
else 
  KUBECTL_DELETE="parallel -j 15 $KUBECTL_DELETE"
fi

for R in $($KUBECTL api-resources --namespaced=true -o name); do
  if grep -q "$R" <<< "$UNWANTED"; then
    continue
  fi
  echo "Deleting $NAMESPACE/$R..."
  $KUBECTL_DELETE "$R"
done
