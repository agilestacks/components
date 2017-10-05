.DEFAULT_GOAL := deploy

export DOMAIN_NAME          ?= dev.kubernetes.delivery
export AWS_DEFAULT_REGION   ?= us-east-2

export AWS_S3_BUCKET        ?= files.$(DOMAIN_NAME)
export AWS_ASSUME_ROLE      ?= master-00b56151b407c3573a2faa6823
export AWS_KEY_PAIR         ?= agilestacks
export AWS_ACCOUNT_ID       ?= $(shell aws sts get-caller-identity --output text --query 'Account')
export AWS_ALIAS            ?= $(firstword $(shell aws iam list-account-aliases --max-items=1 --query 'AccountAliases[0]' --output text) aws-default)

export KUBE_CONTEXT         := $(shell kubectl config current-context)

export AWS_ECR_LOGIN_STRING ?= $(shell aws ecr get-login)
export AWS_ECR_USER         ?= $(word 4,$(AWS_ECR_LOGIN_STRING))
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
export AWS_ECR_REGISTRY     ?= $(subst https://,,$(lastword $(AWS_ECR_LOGIN_STRING)))
export SHELL                := /bin/bash
export SPINNAKER_VERSION    ?= 1.4.2

COMPONENT_NAME    ?= spinnaker
SLACK_TOKEN       ?= unknown
INGRESS_FQDN      ?= spinnaker.app.$(DOMAIN_NAME)
JENKINS_ADDRESS   ?= http://jenkins.jenkins.svc.cluster.local:8080
JENKINS_INGRESS   ?= jenkins.app.$(DOMAIN_NAME)
JENKINS_USER      ?= robot
JENKINS_PASSWORD  ?= password

hal ?= hal --color=false

install:
	sudo $(SHELL) bin/$(shell uname -s | tr A-Z a-z)/InatallHalyard.sh


configure:
	mkdir -p .hub/$(DOMAIN_NAME)
	@echo $(word 6,$(AWS_ECR_LOGIN_STRING)) > .hub/$(DOMAIN_NAME)/ecr-pass.txt

	$(hal) config --set-current-deployment $(DOMAIN_NAME) --deployment $(DOMAIN_NAME)
	$(hal) config provider aws account delete $(AWS_ALIAS) || true
	$(hal) config provider aws account add $(AWS_ALIAS) \
		--account-id $(AWS_ACCOUNT_ID) \
		--assume-role $(AWS_ASSUME_ROLE) \
		--default-key-pair $(AWS_KEY_PAIR) \
		--regions $(AWS_DEFAULT_REGION)

	$(hal) config version edit --version=$(SPINNAKER_VERSION)
	$(hal) config provider docker-registry enable
	$(hal) config provider docker-registry account delete ecr-$(AWS_DEFAULT_REGION) || true
	$(hal) config provider docker-registry account add ecr-$(AWS_DEFAULT_REGION) \
		--username $(AWS_ECR_USER) \
		--password-file .hub/$(DOMAIN_NAME)/ecr-pass.txt \
		--address $(AWS_ECR_REGISTRY) || true

ifeq ($(SLACK_TOKEN),unknown)
	$(hal) config notification slack disable
else
	$(hal) config notification slack enable
	echo $(SLACK_TOKEN) | \
		$(hal) config notification slack edit \
			--bot-name spinnaker \
			--token
endif
	$(hal) config provider kubernetes enable
	$(hal) config provider kubernetes account delete $(subst .,-,$(DOMAIN_NAME)) || true
	$(hal) config provider kubernetes account add $(subst .,-,$(DOMAIN_NAME)) \
		--docker-registries ecr-$(AWS_DEFAULT_REGION) \
		--context $(shell kubectl config current-context)

	$(hal) config storage s3 edit \
		--region $(AWS_DEFAULT_REGION) \
		--root-folder /spinnaker \
		--bucket $(AWS_S3_BUCKET) \
		--assume-role $(AWS_ASSUME_ROLE) \

	$(hal) config security ui  edit --override-base-url http://$(COMPONENT_NAME).$(INGRESS_FQDN)
	$(hal) config security api edit --override-base-url http://api.$(COMPONENT_NAME).$(INGRESS_FQDN)

	$(hal) config ci jenkins enable
	$(hal) config ci jenkins master delete $(JENKINS_INGRESS) || true
	@echo $(JENKINS_PASSWORD) | \
		$(hal) config ci jenkins master add $(JENKINS_INGRESS) \
			--no-validate \
			--address $(JENKINS_ADDRESS) \
			--username $(JENKINS_USER) \
			--password
.PHONY: configure

deploy: configure
	$(hal) config storage edit --type redis
	$(hal) config storage edit --type s3
	$(hal) config deploy edit \
		--account-name $(subst .,-,$(DOMAIN_NAME)) \
		--type distributed
	$(hal) deploy apply
.PHONY: deploy

undeploy:
	@echo "Undeploy Spinnaker"
	$(hal) deploy clean --quiet || true
	@echo "Done"
stop-proxy:
	@docker stop halyard || true
.PHONY: stop-proxy
.PHONY: undeploy

clean:
	rm -rf ~/.hal/*
	rm -rf .hal/$(DOMAIN_NAME)

