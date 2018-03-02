#!/bin/sh -x

echo Undeploying Hello Web

name=hello-web-$NAME
kubectl="kubectl --context=$DOMAIN_NAME"
$kubectl delete -f ingress.yaml
$kubectl delete service $name
$kubectl delete deployment $name
