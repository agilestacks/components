#!/bin/sh -x
if test ! -f $CLOUD_KIND.yaml; then exit 0; fi
cat $CLOUD_KIND.yaml
exec kubectl --context="$DOMAIN_NAME" apply -f $CLOUD_KIND.yaml
