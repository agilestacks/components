#!/bin/sh
exec kubectl --context="$DOMAIN_NAME" apply -f $CLOUD_KIND.yaml
