#!/bin/bash -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name rick04.dev.superhub.io --max-items 1 | jq -Mr .HostedZones[0].Id | sed -e 's/\/hostedzone\///')
ELB=""
echo "Waiting for Load Balancer"
for i in {1..30}; do
  ELB=$(kubectl --namespace="gitlab" describe svc gitlab-cn-nginx-ingress-controller | grep Ingress | awk '{print $3}')
  if [ ! -z "${ELB}" ]; then
    break
  fi
  echo "retry ${i}..."
  sleep 3;
done

#echo "Check if gitlab.rick04.dev.superhub.io exists"
#record=$(
#    aws route53 list-resource-record-sets --hosted-zone-id "${ZONE_ID}" --start-record-name "rick04.dev.superhub.io." --start-record-type "CNAME" \
#    | jq -Mc ".ResourceRecordSets[] | select(.Name == \"git.rick04.dev.superhub.io\")" \
#)

#if [ ! -z "${record}" ]; then
#  echo "Record git.rick04.dev.superhub.io already exists \n Skip DNS UPSERT"
#  exit 0
#fi

echo "Create gitlab.rick04.dev.superhub.io CNAME for ${ELB}"
cat << EOF > ${DIR}/upsert.json
{
  "Comment": "Gitlab SSH ELB",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "gitlab.rick04.dev.superhub.io",
      "Type": "CNAME",
      "TTL": 30,
      "ResourceRecords": [{
        "Value": "${ELB}"
      }]
    }
  },
  {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "registry.rick04.dev.superhub.io",
      "Type": "CNAME",
      "TTL": 30,
      "ResourceRecords": [{
        "Value": "${ELB}"
      }]
    }
  }]
}
EOF

CHANGE_ID=$(
  aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch=file://${DIR}/upsert.json  \
    | jq  -Mr '.ChangeInfo.Id'
)

if [ -n "${CHANGE_ID}" ]; then
  for i in $(seq 1 60); do
    _status=$(
      aws route53 get-change --id ${CHANGE_ID} | jq  -Mr '.ChangeInfo.Status'
    )
    echo "Wait to propagate DNS record: ${_status}"
    test "${_status}" == "INSYNC" && break
    sleep 3
  done
else
  echo There\'s no DNS update needed
fi

