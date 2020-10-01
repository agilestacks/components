NAMESPACE=$1
TIMEOUT=${TIMEOUT:-180}
POD_SECRET=$(kubectl -n $NAMESPACE get secrets | grep harbor-tls |awk '{print $1}')
echo "adding ca.crt to '${POD_SECRET}'"
timeout ${TIMEOUT} bash <<EOT
    while true; do
        kubectl patch secret \
            -n harbor ${POD_SECRET} \
            -p="{\"data\":{\"ca.crt\": \"$(kubectl get secret \
            -n harbor ${POD_SECRET} \
            -o json -o=jsonpath="{.data.tls\.crt}" \
            | base64 -d | awk 'f;/-----END CERTIFICATE-----/{f=1}' - | openssl enc -A -base64)\"}}" > /dev/null 2>&1
        if [[ ${?} -eq 0 ]]; then
            break
        fi
        sleep 2
        printf "."
    done
EOT