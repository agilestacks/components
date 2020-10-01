NAMESPACE=$1
TIMEOUT=${TIMEOUT:-360}
COUNTER=0

echo "adding ca.crt to harbor"
while [[ ${COUNTER} -ne ${TIMEOUT} ]]
do  
    POD_SECRET=$(kubectl -n $NAMESPACE get secrets | grep harbor-tls |awk '{print $1}')
    
    kubectl patch secret \
            -n harbor ${POD_SECRET} \
            -p="{\"data\":{\"ca.crt\": \"$(kubectl get secret \
            -n harbor ${POD_SECRET} \
            -o json -o=jsonpath="{.data.tls\.crt}" \
            | base64 -d | awk 'f;/-----END CERTIFICATE-----/{f=1}' - | openssl enc -A -base64)\"}}" > /dev/null 2>&1
    if [[ ${?} -eq 0 ]]; then
        echo "Patched harbor secret"
        exit 0
    fi

    let COUNTER=COUNTER+1
    sleep 2
done

echo "failed to patch harbor secret"
exit 1
