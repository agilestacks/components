#!/bin/sh -xe

az group deployment create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $COMPONENT_NAME \
    --template-file azuredeploy.json \
    --parameters params.json

set +x
echo
echo Outputs:
az group deployment show \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $COMPONENT_NAME | \
  jq -r '.properties.outputs | to_entries[] | .key + " = " + .value.value'
echo
