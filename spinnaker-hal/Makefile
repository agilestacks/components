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

export SPINNAKER_FQDN       ?= spinnaker.app.$(TF_VAR_name).$(TF_VAR_base_domain)

HALYARD_HOME                ?= $(abspath .hal)/$(TF_VAR_name).$(TF_VAR_base_domain)
hal ?= $(abspath .)/hal --color=false
# hal ?= @docker exec -it halyard bash /usr/local/bin/hal

deploy: init start-proxy wait configure install stop-proxy

undeploy: start-proxy wait delete stop-proxy clean

init:
	@mkdir -p $(HALYARD_HOME)
	@echo $(word 6,$(AWS_ECR_LOGIN_STRING)) > $(HALYARD_HOME)/.ecr-pass.txt

start-proxy: stop-proxy
	@docker pull gcr.io/spinnaker-marketplace/halyard:stable
	docker run -d \
		--name halyard --rm \
		-v $(HALYARD_HOME):/root/.hal \
		-v ~/.kube:/root/.kube:ro \
		-v ~/.aws:/root/.aws:ro \
		-v /$(shell pwd):$(shell pwd) \
		-v $(STACK_K8S_AWS):$(STACK_K8S_AWS):ro \
		-v $(HALYARD_HOME)/.ecr-pass.txt:$(HALYARD_HOME)/.ecr-pass.txt \
		gcr.io/spinnaker-marketplace/halyard:stable
.PHONY: start-proxy

wait:
	@for i in $$(seq 1 60); do \
		if $(hal) --ready; then \
			exit 0; \
		fi; \
		echo "Waiting for halyard container is up and running ($$i)..."; \
		sleep 1; \
	done; \
	echo "Timeout waiting for halyard" \
	exit 1
.PHONY: wait

configure:
	$(eval AWS_ECR_LOGIN_STRING=$(shell aws ecr get-login))
	$(eval AWS_ECR_USER=$(word 4,$(AWS_ECR_LOGIN_STRING)))
	$(eval AWS_ECR_REGISTRY=$(lastword $(AWS_ECR_LOGIN_STRING)))

	$(hal) config version edit --version=1.4.1
	$(hal) config provider docker-registry enable
	$(hal) config provider docker-registry account add ecr \
		--username $(AWS_ECR_USER) \
		--password-file $(HALYARD_HOME)/.ecr-pass.txt \
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

	$(hal) config security ui edit --override-base-url http://$(SPINNAKER_FQDN)
	# $(hal) config security authn oauth2 edit --pre-established-redirect-uri http://api.$(SPINNAKER_FQDN)
	$(hal) config security api edit --override-base-url http://api.$(SPINNAKER_FQDN)
.PHONY: configure

install:
	$(hal) config storage edit --type s3
	$(hal) config deploy edit \
		--account-name kubernetes \
		--type distributed
	$(hal) deploy apply
.PHONY: halyard-deploy

delete:
	@echo "Undeploy Spinnaker"
	$(hal) deploy clean --quiet || true
	@echo "Done"
.PHONY: delete

stop-proxy:
	@docker stop halyard || true
.PHONY: stop-proxy

clean:
	rm -rf $(HALYARD_HOME)
