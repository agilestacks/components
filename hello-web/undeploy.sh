#!/bin/sh -e

echo Undeploying Hello Web

name=hello-web-$NAME
kubectl delete -f ingress.yaml
kubectl delete service $name
kubectl delete deployment $name
