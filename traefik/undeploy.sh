#!/bin/bash

. /etc/environment
. /etc/functions

SERVICE_NAME=traefik
NAMESPACE=${NAMESPACE:-"ingress"}
CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function delete_r53_record() {
  local record=$(
    aws route53 list-resource-record-sets --hosted-zone-id "${ZONE_ID}" --start-record-name "${ROOT_DOMAIN_NAME}." --start-record-type "CNAME" \
    | jq -Mc ".ResourceRecordSets[] | select(.Name == \"$1\") | {\"Changes\":[{\"Action\": \"DELETE\",\"ResourceRecordSet\": .} ]}" \
  )

  test -z "${record}" && return 0
  echo "Delete $1"
  local change_id=$(
    aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch "${record}" \
    | jq  -Mr '.ChangeInfo.Id'
  )

  for i in $(seq 1 60); do
    local _status=$(
      aws route53 get-change --id ${change_id} | jq  -Mr '.ChangeInfo.Status'
    )
    echo "Wait to propagate ${_status}"
    test "${_status}" == "INSYNC" && break
    sleep 3
  done
}

delete_r53_record "\\\\052.app.${ROOT_DOMAIN_NAME}."
delete_r53_record "app.${ROOT_DOMAIN_NAME}."

/opt/bin/kubectl --namespace="${NAMESPACE}" delete configmap traefik-config || true
/opt/bin/kubectl --namespace="${NAMESPACE}" delete -f /srv/kubernetes/ingress/service.yaml || true
/opt/bin/kubectl --namespace="${NAMESPACE}" delete -f /srv/kubernetes/ingress/dashboard-service.yaml || true
/opt/bin/kubectl --namespace="${NAMESPACE}" delete -f /srv/kubernetes/ingress/deployment.yaml || true
/opt/bin/kubectl --namespace="${NAMESPACE}" delete -f /srv/kubernetes/ingress/dashboard-ingress.yaml || true
