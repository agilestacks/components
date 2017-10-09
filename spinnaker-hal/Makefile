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
export AWS_ECR_REGISTRY     ?= $(subst https://,,$(lastword $(AWS_ECR_LOGIN_STRING)))
export SHELL                := /bin/bash
export SPINNAKER_VERSION    ?= 1.4.2
export NAMESPACE            ?= spinnaker

COMPONENT_NAME    ?= spinnaker
SLACK_TOKEN       ?= unknown
INGRESS_FQDN      ?= spinnaker.app.$(DOMAIN_NAME)
JENKINS_ADDRESS   ?= http://jenkins.jenkins.svc.cluster.local:8080
JENKINS_INGRESS   ?= jenkins.app.$(DOMAIN_NAME)
JENKINS_USER      ?= robot
JENKINS_PASSWORD  ?= password

hal ?= hal --color=false
kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(JENKINS_NAMESPACE)"

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
		--context $(DOMAIN_NAME)

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

	$(kubectl) apply -f ingress.yaml
.PHONY: deploy

undeploy:
	$(kubectl) delete -f ingress.yaml || true
	@echo "Undeploy Spinnaker"
	$(hal) deploy clean --quiet || true
	@echo "Done"
.PHONY: undeploy

clean:
	rm -rf ~/.hal/*
	rm -rf .hal/$(DOMAIN_NAME)

