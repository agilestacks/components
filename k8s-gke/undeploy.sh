#!/bin/bash -x

if gcloud dns managed-zones list --filter dnsName:$DOMAIN_NAME | grep -F $DOMAIN_NAME; then
    name=$(echo $DOMAIN_NAME | cut -d. -f1)
    endpoint=$(gcloud container clusters describe $GKE_CLUSTER --zone $GCP_ZONE --format json | jq -r .endpoint)

    rm -f transaction.yaml
    gcloud dns record-sets transaction start -z $name
    gcloud dns record-sets transaction remove -z $name --name $DOMAIN_NAME --type A --ttl 300 $endpoint
    gcloud dns record-sets transaction execute -z $name

    gcloud dns managed-zones delete $name
fi
