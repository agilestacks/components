#!/bin/bash

# Verify Route53 zone is unique then print Hosted Zone Id if exist
# Exit with error if not unique
# This won't work very well for a mix of public and private zones

AWS="${AWS:-aws}"
JQ="${JQ:-jq}"
DOMAIN="$1"
if test -z "$DOMAIN"; then echo "Usage: $0 <domain.name>"; exit 1; fi

TF_VAR_aws_access_key_id="${TF_VAR_aws_access_key_id:=}"
TF_VAR_aws_secret_access_key="${TF_VAR_aws_secret_access_key:=}"

# A hack: If the Route53 zone is in another AWS account, AWS credentials of
# that account should be used
if [ -n "$TF_VAR_aws_access_key_id" ]; then
  unset AWS_SESSION_TOKEN
  export AWS_DEFAULT_REGION=us-east-1
  export AWS_ACCESS_KEY_ID=$TF_VAR_aws_access_key_id
  export AWS_SECRET_ACCESS_KEY=$TF_VAR_aws_secret_access_key
fi

route53_zones_resp=$($AWS --output=json route53 list-hosted-zones-by-name --dns-name "$DOMAIN" --max-items 1)
zone=$($JQ .HostedZones[0] <<< "$route53_zones_resp")
test -z "$zone" -o "$zone" = "null" && exit 0

name=$($JQ -r .Name <<< "$zone")
test "$DOMAIN" != "$name" -a "${DOMAIN}." != "$name" && exit 0

next_dns_name=$($JQ -r .NextDNSName <<< "$route53_zones_resp")
if test "$name" = "$next_dns_name"; then
    echo "$name zone is not unique in Route53"
    exit 1
fi

id=$($JQ -r .Id <<< "$zone" | sed -e 's|/hostedzone/||')
echo "$id"
