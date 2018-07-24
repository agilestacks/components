#!/bin/bash -xe

name=$(echo $DOMAIN_NAME | cut -d. -f1)
base_domain=$(echo $DOMAIN_NAME | cut -d. -f2-)

base_domain_zone=agilestacks # this is the name of root zone in Google DNS, this become Cloud Account domain

if ! kubectl config get-contexts $DOMAIN_NAME; then
    if test -z "$GKE_CLUSTER"; then
        echo "GKE_CLUSTER is not set and no Kubeconfig context $DOMAIN_NAME found"
        exit 1
    fi
    gcloud container clusters get-credentials $GKE_CLUSTER --zone $GCP_ZONE
    kubectl config rename-context $(kubectl config current-context) $DOMAIN_NAME
fi

describe=$(gcloud container clusters describe $GKE_CLUSTER --zone $GCP_ZONE --format json)
endpoint=$(echo $describe | jq -r .endpoint)
auth=$(echo $describe | jq -r .masterAuth)
caCert=$(echo $auth | jq -r .clusterCaCertificate)
clientCert=$(echo $auth | jq -r .clientCertificate)
clientKey=$(echo $auth | jq -r .clientKey)

BUCKET=gs://files-$(echo $DOMAIN_NAME | sed -e 's/\./-/g')

if ! gsutil ls $BUCKET; then
    gsutil mb -l $GCP_REGION $BUCKET
fi

if ! gcloud dns managed-zones list --filter dnsName:$DOMAIN_NAME | grep -F $DOMAIN_NAME; then
    if ! gcloud dns managed-zones list --filter dnsName:$base_domain | grep -F $base_domain; then
        echo $base_domain not found in Cloud DNS
        exit 1
    fi
    gcloud dns managed-zones create $name --dns-name=$DOMAIN_NAME --description=$name

    rm -f transaction.yaml
    gcloud dns record-sets transaction start -z $name
    gcloud dns record-sets transaction add -z $name --name api.$DOMAIN_NAME --type A --ttl 300 $endpoint
    gcloud dns record-sets transaction execute -z $name

    gcloud dns record-sets transaction start -z $base_domain_zone
    gcloud dns record-sets transaction add -z $base_domain_zone --name $DOMAIN_NAME --type NS --ttl 300 \
        $(gcloud dns managed-zones describe ${name} --format json | jq -r .nameServers[])
    gcloud dns record-sets transaction execute -z $base_domain_zone
fi

set +x

echo Outputs:
echo
echo dns_name = $name
echo dns_base_domain = $base_domain
echo gcr_repository = gcr.io/$GCP_PROJECT
echo gcs_bucket = $BUCKET
echo api_ca_crt = $caCert
echo api_client_crt = $clientCert
echo api_client_key = $clientKey
echo api_endpoint = api.$DOMAIN_NAME
echo
