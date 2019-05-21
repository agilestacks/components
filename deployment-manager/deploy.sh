#!/bin/sh -xe
if gcloud deployment-manager deployments describe $COMPONENT_NAME; then
    verb=update
else
    verb=create
fi

gcloud deployment-manager deployments $verb --preview $COMPONENT_NAME --config deployment.yaml
sleep 5
gcloud deployment-manager deployments update $COMPONENT_NAME
set +x
echo
echo Outputs:
gcloud --format=json deployment-manager deployments describe $COMPONENT_NAME |
    jq -r '.outputs[] | .name + " = " + .finalValue'
echo