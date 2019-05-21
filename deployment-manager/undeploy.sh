#!/bin/sh -xe
exec gcloud deployment-manager deployments delete -q $COMPONENT_NAME
