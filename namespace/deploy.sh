#!/bin/sh
exec kubectl --context="$DOMAIN_NAME" apply -f namespace.yaml
