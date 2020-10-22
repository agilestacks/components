#!/bin/bash -e

ARGS=$*
# shellcheck disable=SC2086
delete_resource() {
  echo -n "."
  GET_ARGS=$(echo "$*" | sed -e 's/^--all$//g' | xargs)
  if test -n "$(kubectl get -o name $GET_ARGS)"; then
    echo "Cleaning $1 ... "
    # shellcheck disable=SC2048
    kubectl delete $*
  fi
}

max_procs=12
run() {
  echo -n "Please stand by ..."
  # if which parallel > /dev/null 2>&1; then
  #   parallel -j ${max_procs} "delete_resource {} $ARGS"
  if which bash > /dev/null 2>&1; then
    xargs -P${max_procs} -I{} -n1 bash -c "delete_resource {} $ARGS"
  elif which sh > /dev/null 2>&1; then
    xargs -P${max_procs} -I{} -n1 sh -c "delete_resource {} $ARGS"
  else
    while IFS= read -r line; do
      # shellcheck disable=SC2086
      delete_resource $line $ARGS
    done
    fi
} </dev/stdin

export -f delete_resource run
echo "Cleaning resources: $ARGS"
kubectl api-resources --namespaced=true -o name \
  | sed -e 's/^bindings$//g' \
        -e 's/^namespace$//g' \
        -e 's/^events$//g' \
        -e 's/^endpoints$//g' \
        -e 's/^localsubjectaccessreviews.authorization.k8s.io$//g' \
        -e 's/^securitygrouppolicies.vpcresources.k8s.aws$//g' \
  | sed '/^[[:space:]]*$/d' \
  | run

echo "Done!"
