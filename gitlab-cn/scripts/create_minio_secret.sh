#!/bin/bash
# Construct a gitlab registry storage secret using existing minio component secrets
## expects jq 1.6 or later
## expects to be formatted with mustache, not default/golang

SECRETS=$(kubectl -n minio get secret rick-minio -o json | jq '.data | map_values(@base64d)')
MINIO_ACCESS_KEY=$(echo $SECRETS | jq '.accesskey' | tr -d '"')
MINIO_SECRET_KEY=$(echo $SECRETS | jq '.secretkey' | tr -d '"')

echo $MINIO_ACCESS_KEY
echo $MINIO_SECRET_KEY

F=$(mktemp)
REGISTRY_SECRET_FILE=$(cat << END > $F
s3:
  bucket: gitlab-registry-storage
  accesskey: ${MINIO_ACCESS_KEY}
  secretkey: ${MINIO_SECRET_KEY}
  regionendpoint: http://rick-minio.minio:9000
  region: us-east-1
  host: rick-minio.minio
  v4auth: true
END
)

kubectl -n gitlab create secret generic gitlab-registry-storage --from-file=config=$F

F=$(mktemp)
RAILS_SECRET_FILE=$(cat << END > $F
# Specify access/secret keys
provider: AWS
aws_access_key_id: ${MINIO_ACCESS_KEY} 
aws_secret_access_key: ${MINIO_SECRET_KEY}
aws_signature_version: 4
host: rick-minio.minio
endpoint: http://rick-minio.minio:9000
END
)

kubectl -n gitlab create secret generic gitlab-rails-storage --from-file=connection=$F

F=$(mktemp)
BACKUP_SECRET_FILE=$(cat << END > $F
[default]
host_base = rick-minio.minio:9000
host_bucket = rick-minio.minio:9000
use_https = False
signature_v2 = False
access_key = ${MINIO_ACCESS_KEY} 
secret_key = ${MINIO_SECRET_KEY}
enable_multipart = False
END
)

kubectl -n gitlab create secret generic gitlab-backup-storage --from-file=config=$F
