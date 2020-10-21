#!/bin/sh -x
cat $CLOUD_KIND.yaml
exec kubectl --context="$DOMAIN_NAME" apply -f $CLOUD_KIND.yaml
