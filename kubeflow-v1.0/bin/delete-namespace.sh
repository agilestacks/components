#!/bin/bash -e
# shellcheck disable=SC2086
NAMESPACE=$1
shift
ARGS=$*

if test -z "$(kubectl $ARGS get namespace "$NAMESPACE" -o name)"; then
  exit
fi

TIMEOUT=60s
GRACE_PERIOD=5

echo -n "Gracefully deleting namespace $NAMESPACE: "
set +e
kubectl $ARGS delete namespace $NAMESPACE \
  --wait \
  --timeout=$TIMEOUT \
  --grace-period=$GRACE_PERIOD >/dev/null
if test "$?" = "0" && test -z "$(kubectl $ARGS get namespace "$NAMESPACE" -o name)"; then
  echo "$NAMESPACE deleted successfully";
  exit 0
fi
echo "Attempting to force delete: $NAMESPACE"
sleep 5
echo -n "Dropping namespace finalizers: "
kubectl $ARGS get namespace "$NAMESPACE" -o json \
  | jq '. | del(.spec.finalizers)' \
  | kubectl $ARGS replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f - >/dev/null
echo "Done"

echo -n "Deleting starting force delete for: $NAMESPACE"
kubectl $ARGS delete namespace "$NAMESPACE" --force || exit 0
