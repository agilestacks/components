#!/bin/bash -e
# shellcheck disable=SC2155

export MC_HOME="$(pwd)/.mc"

NAMESPACE="${SECRET_NAMESPACE:-minio}"
DOMAIN_NAME="${DOMAIN_NAME:-localhost}"
BUCKET="${BUCKET:-default}"
SECRET_NAME="${SECRET_NAME:-minio}"
ACCESS_KEY_REF="${ACCESS_KEY_REF:=accesskey}"
SECRET_KEY_REF="${SECRET_KEY_REF:-secretkey}"
ARCH="$(uname -s | tr '[:upper:]' '[:lower:]')"

kubectl="kubectl --context=$DOMAIN_NAME --namespace=$NAMESPACE"
base64_decode='base64 -d'
mc='mc --no-color --insecure'

if test "$ARCH" == "darwin"; then
    base64_decode='base64 --decode'
fi

if test "$INGRESS_PROTOCOL" == "https"; then
    mc='mc --no-color'
fi

ALIAS="superhub"
ACCESS_KEY=$($kubectl get secret "$SECRET_NAME" -o "json" | jq -r ".data?.$ACCESS_KEY_REF" | $base64_decode)
SECRET_KEY=$($kubectl get secret "$SECRET_NAME" -o "json" | jq -r ".data?.$SECRET_KEY_REF" | $base64_decode)

# shellcheck disable=SC2046
export MC_HOSTS_${ALIAS}="$INGRESS_PORTOCOL://$ACCESS_KEY:$SECRET_KEY@$ENDPOINT"

echo "Creating bucket $BUCKET"
$mc mb "$ALIAS/$BUCKET" 2>/dev/null || true
$mc ls "$ALIAS"

ARNS="$( $mc admin config get "$ALIAS" \
       | jq '{region: .region, notify: .notify | to_entries[] | {service: .key, args: .value | select(to_entries[].value.enable==true)}}' \
       | jq '"arn:minio:sqs:"+.region+":"+(.notify.args|keys)[]+":"+.notify.service' \
       | xargs )"

ARGS=()
if test ! -z "$EVENT_PREFIX"; then
    ARGS+=(--prefix "$EVENT_PREFIX")
fi
if test ! -z "$EVENT_SUFFIX"; then
    ARGS+=(--suffix "$EVENT_SUFFIX")
fi
if test ! -z "$EVENTS"; then
    ARGS+=(--events "$EVENTS")
fi

for a in $ARNS; do
    echo "Setting event liscener to $a"
    $mc events add "$ALIAS/$BUCKET" "$a" "${ARGS[@]}" 2>/dev/null || true
done
$mc events list "$ALIAS/$BUCKET"

