#!/bin/sh -xe

echo Deploying Hello Web on \`$NAME\` stack in \`$DOMAIN_NAME\` domain

name=hello-web-$NAME
kubectl="kubectl --context=$DOMAIN_NAME"
$kubectl run $name --image=gcr.io/google-samples/hello-app:1.0 --port=8080
$kubectl expose deployment $name --type=ClusterIP
$kubectl apply -f ingress.yaml
