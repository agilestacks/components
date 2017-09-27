.DEFAULT_GOAL := deploy

export TF_VAR_name          ?= dev
export TF_VAR_base_domain   ?= kubernetes.delivery
export TF_VAR_aws_az        ?= us-east-2a
export AWS_DEFAULT_REGION   ?= us-east-2

export AWS_S3_BUCKET        ?= files.$(TF_VAR_name).$(TF_VAR_base_domain)
export AWS_ASSUME_ROLE      ?= master-00b56151b407c3573a2faa6823

export STACK_K8S_AWS        ?= $(abspath ../../stack-k8s-aws)
export KUBE_CONTEXT         := $(shell kubectl config current-context)
export AWS_ECR_LOGIN_STRING ?= $(shell aws ecr get-login))
export AWS_ECR_USER         ?= $(word 4,$(AWS_ECR_LOGIN_STRING))
export AWS_ECR_REGISTRY     ?= $(lastword $(AWS_ECR_LOGIN_STRING))


hal ?= $(abspath .)/hal

init:
	@mkdir -p $(abspath .hal)
	@echo $(word 6,$(AWS_ECR_LOGIN_STRING)) > $(abspath .hal)/.ecr-pass.txt

start-proxy:
	@docker pull gcr.io/spinnaker-marketplace/halyard:stable
	docker run -d -p 127.0.0.1:8084:8084 -p 127.0.0.1:9000:9000 \
		--name halyard --rm \
		-v $(abspath .hal):/root/.hal \
		-v ~/.kube:/root/.kube:ro \
		-v ~/.aws:/root/.aws:ro \
		-v /$(shell pwd):$(shell pwd) \
		-v $(STACK_K8S_AWS):$(STACK_K8S_AWS):ro \
		-v $(abspath .hal)/.ecr-pass.txt:$(abspath .hal)/.ecr-pass.txt \
		gcr.io/spinnaker-marketplace/halyard:stable
	# sleep 3
.PHONY: start-proxy

configure:
	$(eval AWS_ECR_LOGIN_STRING=$(shell aws ecr get-login))
	$(eval AWS_ECR_USER=$(word 4,$(AWS_ECR_LOGIN_STRING)))
	$(eval AWS_ECR_REGISTRY=$(lastword $(AWS_ECR_LOGIN_STRING)))

	$(hal) config version edit --version=1.4.1
	$(hal) config provider docker-registry enable
	$(hal) config provider docker-registry account add ecr \
		--username $(AWS_ECR_USER) \
		--password-file $(abspath .hal)/.ecr-pass.txt \
		--address $(AWS_ECR_REGISTRY:https://%=%) || true

	@echo added registry account ecr
	$(hal) config provider kubernetes enable
	$(hal) config provider kubernetes account add kubernetes \
		--docker-registries ecr \
		--context $(shell kubectl config current-context) || true

	$(hal) config storage s3 edit \
		--region $(AWS_DEFAULT_REGION) \
		--root-folder /spinnaker \
		--bucket $(AWS_S3_BUCKET) \
		--assume-role $(AWS_ASSUME_ROLE)
.PHONY: configure

deploy:
	$(hal) config storage edit --type s3
	$(hal) config deploy edit \
		--account-name kubernetes \
		--type distributed
	$(hal) deploy apply
.PHONY: halyard-deploy

stop-proxy:
	@docker stop halyard || true
.PHONY: stop-proxy

clean:
	rm -rf $(abspath .hal)
