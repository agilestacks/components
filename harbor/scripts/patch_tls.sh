#!/bin/bash

TIMEOUT=${TIMEOUT:-360}
COUNTER=0

export kubectl="kubectl --context=$DOMAIN_NAME --namespace=$NAMESPACE"

echo "adding ca.crt to harbor"
while [[ ${COUNTER} -ne ${TIMEOUT} ]]
do
    POD_SECRET=$($kubectl get secrets --field-selector type=kubernetes.io/tls 2>&1 | grep harbor-tls |awk '{print $1}')
    if [[ -n "${POD_SECRET}" ]]; then
        $kubectl patch secret \
                ${POD_SECRET} \
                -p="{\"data\":{\"ca.crt\": \"$($kubectl get secret \
                ${POD_SECRET} \
                -o json -o=jsonpath="{.data.tls\.crt}" \
                | base64 -d | awk 'f;/-----END CERTIFICATE-----/{f=1}' - | openssl enc -A -base64)\"}}" > /dev/null 2>&1
        if [[ ${?} -eq 0 ]]; then
            echo "Patched harbor secret"
            exit 0
        fi
    fi

    let COUNTER=COUNTER+1
    sleep 2
done

echo "timeout - failed find and patch harbor secret"
exit 1
