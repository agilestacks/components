#!/bin/bash -e

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name oleg24.kubernetes.delivery --max-items 1 | jq -Mr .HostedZones[0].Id | sed -e 's/\/hostedzone\///')

function domain_key() {
    echo $(echo $1 | base64 | sed -e "s/=/_/g")
}

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
  DOMAIN_KEY=$(domain_key $1)
  eval CHANGE_ID_$DOMAIN_KEY=$change_id

}

function wait_r53_status() {
  DOMAIN_KEY=$(domain_key $1)

  eval local change_id=\$CHANGE_ID_$DOMAIN_KEY
  test -z $change_id && return 0

  echo "Waiting for $1";

  for i in $(seq 1 60); do
    local _status=$(
      aws route53 get-change --id ${change_id} | jq  -Mr '.ChangeInfo.Status'
    )
    echo "Wait to propagate ${_status}"
    test "${_status}" == "INSYNC" && break
    sleep 3
  done

}

delete_r53_record "\\\\052.apps.oleg24.kubernetes.delivery."
delete_r53_record "apps.oleg24.kubernetes.delivery."
delete_r53_record "\\\\052.app.oleg24.kubernetes.delivery."
delete_r53_record "app.oleg24.kubernetes.delivery."
delete_r53_record "auth.oleg24.kubernetes.delivery."

wait_r53_status "\\\\052.apps.oleg24.kubernetes.delivery."
wait_r53_status "apps.oleg24.kubernetes.delivery."
wait_r53_status "\\\\052.app.oleg24.kubernetes.delivery."
wait_r53_status "app.oleg24.kubernetes.delivery."
wait_r53_status "auth.oleg24.kubernetes.delivery."
