#!/bin/sh -xe
exec az group deployment delete \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $COMPONENT_NAME
