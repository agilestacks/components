#!/bin/bash -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name oleg24.kubernetes.delivery --max-items 1 | jq -Mr .HostedZones[0].Id | sed -e 's/\/hostedzone\///')
ELB=""
echo "Waiting for Load Balancer"
for i in {1..30}; do
  ELB=$(kubectl --namespace="ingress" describe service traefik-traefik | grep Ingress | awk '{print $3}')
  if [ ! -z "${ELB}" ]; then
    break
  fi
  echo "retry..."
  sleep 3;
done

echo "Check if app.oleg24.kubernetes.delivery exists in public DNS zone."
record=$(
    aws route53 list-resource-record-sets --hosted-zone-id "${ZONE_ID}" --start-record-name "oleg24.kubernetes.delivery." --start-record-type "CNAME" \
    | jq -Mc ".ResourceRecordSets[] | select(.Name == \"app.oleg24.kubernetes.delivery\")" \
)

if [ ! -z "${record}" ]; then
  echo "Record app.oleg24.kubernetes.delivery already exists in public DNS zone \n Skip DNS UPSERT"
  exit 0
fi

echo "Create app.oleg24.kubernetes.delivery, apps.oleg24.kubernetes.delivery and auth.oleg24.kubernetes.delivery CNAMEs for ${ELB} in public DNS zone."
cat << EOF > ${DIR}/upsert-public.json
{
  "Comment": "Traefik ingress",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "app.oleg24.kubernetes.delivery",
      "Type": "CNAME",
      "TTL": 30,
      "ResourceRecords": [{
        "Value": "${ELB}"
      }]
    }
  }, {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "*.app.oleg24.kubernetes.delivery",
      "Type": "CNAME",
      "TTL": 30,
      "ResourceRecords": [{
        "Value": "${ELB}"
      }]
    }
  }, {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "apps.oleg24.kubernetes.delivery",
      "Type": "CNAME",
      "TTL": 30,
      "ResourceRecords": [{
        "Value": "${ELB}"
      }]
    }
  }, {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "*.apps.oleg24.kubernetes.delivery",
      "Type": "CNAME",
      "TTL": 30,
      "ResourceRecords": [{
        "Value": "${ELB}"
      }]
    }
  }, {
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "auth.oleg24.kubernetes.delivery",
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
  aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch=file://${DIR}/upsert-public.json  \
    | jq  -Mr '.ChangeInfo.Id'
)

for i in $(seq 1 60); do
  _status=$(
    aws route53 get-change --id ${CHANGE_ID} | jq  -Mr '.ChangeInfo.Status'
  )
  echo "Wait to propagate DNS record: ${_status}"
  test "${_status}" == "INSYNC" && break
  sleep 3
done
