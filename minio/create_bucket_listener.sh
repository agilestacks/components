#!/bin/bash

# In order to support clients such as Argo, we need to configure minio events to emit an event
# This script downloads minio-client and uses it to create a listener on the specified bucket

if [ -z "asi-rick-minio-events" ]; then
  echo "component.minio.event-bucket not specified. Skipping minio event listener configuration"
  exit 0
fi

OS=$(uname | tr A-Z a-z)

POD_NAME=""
while [ -z "$POD_NAME" ]; do
    POD_NAME=$(kubectl --context="$DOMAIN_NAME" --namespace="$NAMESPACE" get pods -l "release=minio" -o jsonpath="{.items[0].metadata.name}")
done


MINIO_ARN=""
while [ -z $MINIO_ARN ]; do
  sleep 2
  MINIO_ARN=$(kubectl --context="$DOMAIN_NAME" --namespace="$NAMESPACE" logs $POD_NAME | grep "SQS ARNs" | cut -d' ' -f4);
done

nohup kubectl port-forward $POD_NAME 9000 --namespace minio &
PF_PID=$!
sleep 2
wget https://dl.minio.io/client/mc/release/$(OS)-amd64/mc
chmod +x mc
mc config host add minio-local http://localhost:9000 AKIAIOSFODNN7EXAMPLE wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY S3v4
mc mb minio-local/asi-rick-minio-events
mc events add minio-local/asi-rick-minio-events $MINIO_ARN
kill $PF_PID
