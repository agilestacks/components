#!/bin/bash -e

SERVICE_NAME=gitlab-ce
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
$AWS=/opt/bin/aws

. /etc/functions


# The following comment block is for creating a postgres RDS instance instead of using the
# postgres helm (local PVC based installation) 
#MAC=$(cat /sys/class/net/eth0/address)

#VPC_SUBNET=$(curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/${MAC}/subnet-id)

#RESULT=$($AWS rds create-db-instance \
#  --db-instance-identifier gitlab-ce.${ROOT_DOMAIN_NAME} \
#  --allocated-storage 20 \
#  --db-instance-class db.m1.small \
#  --engine postgres \
#  --master-username gitlab \
#  --master-user-password gitlab \
#  --no-publicly-accessible \
#  --db-subnet-group-name ${VPC_SUBNET})
#
#PG_ENDPOINT=$(echo $RESULT | jq '.Endpoint.Address')

#aws rds wait db-instance-available --db-instance-identifier gitlab-ce.${ROOT_DOMAIN_NAME}



pushd $DIR

cat << EOF > values.yaml
image: gitlab/gitlab-ce:9.3.3-ce.0
externalUrl: gitlab.app.${ROOT_DOMAIN_NAME}
gitlabRootPassword: "gitlab"
serviceType: LoadBalancer

postgresql:
  # 9.6 is the newest supported version for the GitLab container
  imageTag: "9.6"
  cpu: 1000m
  memory: 1Gi

  postgresUser: gitlab
  postgresPassword: gitlab
  postgresDatabase: gitlab

  persistence:
    size: 10Gi

sshPort: 22
httpPort: 80
httpsPort: 443

resources:
  requests:
    memory: 1Gi
    cpu: 500m
  limits:
    memory: 2Gi
    cpu: 1

persistence:
  ## This volume persists generated configuration files, keys, and certs.
  ##
  gitlabEtc:
    enabled: true
    size: 1Gi
    ## If defined, volume.beta.kubernetes.io/storage-class: <storageClass>
    ## Default: volume.alpha.kubernetes.io/storage-class: default
    ##
    # storageClass:
    accessMode: ReadWriteOnce
  ## This volume is used to store git data and other project files.
  ## ref: https://docs.gitlab.com/omnibus/settings/configuration.html#storing-git-data-in-an-alternative-directory
  ##
  gitlabData:
    enabled: true
    size: 10Gi
    ## If defined, volume.beta.kubernetes.io/storage-class: <storageClass>
    ## Default: volume.alpha.kubernetes.io/storage-class: default
    ##
    # storageClass:
    accessMode: ReadWriteOnce

redis:
  redisPassword: "gitlab"

  resources:
    requests:
      memory: 1Gi

  persistence:
    size: 10Gi

okta:
  certFingerprint:  $OKTA_CERT_FINGERPRINT
  ssoTarget: $OKTA_SSO_TARGET
  certIssuer: $OKTA_CERT_ISSUER 
EOF

helm install --name gitlab-ce -f values.yaml ./

popd
