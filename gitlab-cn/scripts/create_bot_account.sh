#!/bin/bash -x

ROOT_PASSWORD=$(kubectl -n gitlab get secret gitlab-cn-gitlab-initial-root-password -o json | jq --raw-output '.data | map_values(@base64d) | .password')

BOT_NAME=gitbot
BOT_PASSWORD=ASIWinning@Gitlab
TOKEN=

REQUEST="grant_type=password&username=root&password=${ROOT_PASSWORD}"

while [ -z "$TOKEN" ]
do
  RESULT=$(curl -H"Accept: application/json" --data "${REQUEST}" --request POST https://gitlab.rick04.dev.superhub.io/oauth/token)
    TOKEN=$(echo $RESULT | jq --raw-output .access_token)
    if [ -z "$TOKEN" ]; then
        echo "Failed to log into gitlab. Service is still unavailable. Retrying ..."
	sleep 1
    fi
done

if [ $TOKEN == "null" ]; then
    echo "Failed to log into gitlab-ce"
fi

curl -H "Authorization: Bearer ${TOKEN}" https://gitlab.rick04.dev.superhub.io/api/v4/users --data "username=${BOT_NAME}&email=${BOT_NAME}@rick04.dev.superhub.io&password=${BOT_PASSWORD}&name=gitbot&admin=true"
