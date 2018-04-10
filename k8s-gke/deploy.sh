#!/bin/bash -xe

DOMAIN_NAME=${TF_VAR_name}.${TF_VAR_base_domain}
base_domain_zone=kubernetes

if ! kubectl config get-contexts $DOMAIN_NAME; then
    if test -z "$GKE_CLUSTER"; then
        echo "GKE_CLUSTER is not set and no Kubeconfig context $DOMAIN_NAME found"
        exit 1
    fi
    gcloud container clusters get-credentials $GKE_CLUSTER --zone $GCP_ZONE
    kubectl config rename-context $(kubectl config current-context) $DOMAIN_NAME
fi

BUCKET=gs://files-$(echo $DOMAIN_NAME | sed -e 's/\./-/g')

if ! gsutil ls $BUCKET; then
    gsutil mb -l $GCP_REGION $BUCKET
fi

if ! gcloud dns managed-zones list --filter dnsName:$DOMAIN_NAME | grep -F $DOMAIN_NAME; then
    if ! gcloud dns managed-zones list --filter dnsName:$TF_VAR_base_domain | grep -F $TF_VAR_base_domain; then
        echo $TF_VAR_base_domain not found in Cloud DNS
        exit 1
    fi
    gcloud dns managed-zones create $TF_VAR_name --dns-name=$DOMAIN_NAME --description=$TF_VAR_name

    rm -f transaction.yaml
    gcloud dns record-sets transaction start -z $TF_VAR_name
    gcloud dns record-sets transaction add -z $TF_VAR_name --name $DOMAIN_NAME --type A --ttl 300 \
        $(gcloud container clusters describe cluster-1 --zone $GCP_ZONE --format json | jq -r .endpoint)
    gcloud dns record-sets transaction execute -z $TF_VAR_name

    gcloud dns record-sets transaction start -z $base_domain_zone
    gcloud dns record-sets transaction add -z $base_domain_zone --name $DOMAIN_NAME --type NS --ttl 300 \
        $(gcloud dns managed-zones describe ${TF_VAR_name} --format json | jq -r .nameServers[])
    gcloud dns record-sets transaction execute -z $base_domain_zone
fi

auth=$(gcloud container clusters describe cluster-1 --zone $GCP_ZONE --format json | jq -r .masterAuth)
caCert=$(echo $auth | jq -r .clusterCaCertificate)
clientCert=$(echo $auth | jq -r .clientCertificate)
clientKey=$(echo $auth | jq -r .clientKey)

set +x

echo Outputs:
echo
echo base_domain = $DOMAIN_NAME
echo gcr_repository = gcr.io/$GCP_PROJECT
echo gcp_bucket = $BUCKET
echo api_ca_crt = $caCert
echo api_client_crt = $clientCert
echo api_client_key = $clientKey
echo
