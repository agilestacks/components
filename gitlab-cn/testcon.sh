#!/bin/bash -x


TOKEN=$(curl --user 'robogit:ASIWinning@Gitlab' 'https://gitlab.rick04.dev.superhub.io/jwt/auth?client_id=docker&offline_token=true&service=container_registry&scope=repository:robogit/thisworkss:push,list,pull' | jq --raw-output '.token')
curl -vvv -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -H "Authorization: Bearer $TOKEN" https://registry.rick04.dev.superhub.io/v2/robogit/thisworkss/tags/list
