.DEFAULT_GOAL := deploy

BUCKET      ?= argo
ENDPOINT    ?= localhost:9000
SECRET_NAME ?= minio
CONFIGMAP   ?= workflow-controller-configmap
INGRESS_PORTOCOL ?= http
NAMESPACE   ?= minio
kubectl     ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy: install output

install:
	- $(kubectl) create configmap $(CONFIGMAP) --from-file configmap.yaml
	$(CURDIR)/mb.sh

output:
	@ echo
	@ echo Outputs:
	@ echo secret_name = $(SECRET_NAME)
	@ echo endpoint = $(ENDPOINT)
	@ echo iam_user_name =
	@ echo iam_user_arn =
	@ echo insecure = true
	@ echo


undeploy:
	- $(kubectl) delete $(CONFIGMAP)


.PHONY: output install undeploy
