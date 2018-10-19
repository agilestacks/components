.DEFAULT_GOAL := deploy

export NAME                 ?= dev
export DOMAIN_NAME          ?= dev.kubernetes.delivery
export AWS_DEFAULT_REGION   ?= us-east-2

export SHELL                := /bin/bash
export HOME                 ?= /home/spinnaker

export TF_LOG               ?= debug
export TF_LOG_PATH          ?= .terraform/$(DOMAIN_NAME).log
export TF_INPUT             := 0
export TF_OPTS              :=
export TF_UPDATE            ?= -update

export STATE_BUCKET ?= terraform.agilestacks.com
export STATE_REGION ?= us-east-1

COMPONENT_NAME       ?= spinnaker
SLACK_TOKEN          ?=
INGRESS_PROTOCOL     ?= http
INGRESS_FQDN         ?= apps.$(DOMAIN_NAME)
JENKINS_ADDRESS      ?= http://jenkins.jenkins.svc.cluster.local:8080
JENKINS_FQDN         ?= jenkins.app.$(DOMAIN_NAME)
JENKINS_USER         ?= robot
JENKINS_PASSWORD     ?= password
SPINNAKER_VERSION    ?= 1.10.0
NAMESPACE            ?= spinnaker
AWS_S3_BUCKET        ?= files.$(DOMAIN_NAME)
AWS_KEYPAIR          ?= agilestacks

AWS_ECR_LOGIN_STRING := $(shell aws ecr get-login)
AWS_ECR_USER         := $(word 4,$(AWS_ECR_LOGIN_STRING))
AWS_ECR_REGISTRY     := $(subst https://,,$(lastword $(AWS_ECR_LOGIN_STRING)))

AWS_ACCOUNT_NAME     ?= aws
K8S_ACCOUNT_NAME     ?= kubernetes

terraform            ?= terraform
hal 			     ?= hal --color=false
kubectl 		     ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

tf_init:
	@mkdir -p .terraform/$(DOMAIN_NAME)
	@rm -rf .terraform/$(DOMAIN_NAME)/*
	$(terraform) init -get=true $(TF_CMD_OPTS) -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="region=$(STATE_REGION)" \
		-backend-config="key=$(DOMAIN_NAME)/spinnaker/$(COMPONENT_NAME)/terraform.tfstate" \
		-backend-config="profile=$(AWS_PROFILE)" \
		. .terraform/$(DOMAIN_NAME)

tf_plan:
	cd .terraform/$(DOMAIN_NAME) && \
		$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=terraform.tfplan
.PHONY: tf_plan

tf_apply:
	cd .terraform/$(DOMAIN_NAME) && \
		$(terraform) apply $(TF_OPTS) -Xshadow=false terraform.tfplan
	@echo
.PHONY: tf_apply

tf_destroy: tf_init
	cd .terraform/$(DOMAIN_NAME) && \
		$(terraform) plan $(TF_OPTS) -destroy -refresh=true -module-depth=-1 -out=terraform.tfplan
	$(MAKE) tf_apply
.PHONY: tf_destroy

install:
	sudo $(SHELL) bin/$(shell uname -s | tr A-Z a-z)/InstallHalyard.sh

tf_output=$(shell cd .terraform/$(DOMAIN_NAME) && $(terraform) output -json | jq -crM .$(1).value)

# long deployment name results in
# $ hal backup create
# ERROR Unexpected exception: java.lang.RuntimeException: file name
# '...'
# is too long ( > 100 bytes)
configure:
	$(eval AWS_ACCOUNT_ID  := $(call tf_output,account_id))
	$(eval AWS_ASSUME_ROLE := $(call tf_output,role_name))

	mkdir -p $(HOME)/.hal
	@echo $(word 6,$(AWS_ECR_LOGIN_STRING)) > $(HOME)/.hal/$(NAME)-ecr-pass.txt

	$(hal) config --set-current-deployment $(NAME) --deployment $(NAME)
	$(hal) config version edit --version=$(SPINNAKER_VERSION)
	$(hal) config provider aws account delete $(AWS_ACCOUNT_NAME) || true
	$(hal) config provider aws account add $(AWS_ACCOUNT_NAME) \
		--account-id $(AWS_ACCOUNT_ID) \
		--assume-role role/$(AWS_ASSUME_ROLE) \
		--default-key-pair $(AWS_KEYPAIR) \
		--regions $(AWS_DEFAULT_REGION)
	$(hal) config provider aws enable

	$(hal) config provider docker-registry account delete aws-ecr-$(AWS_DEFAULT_REGION) || true
	$(hal) config provider docker-registry account add aws-ecr-$(AWS_DEFAULT_REGION) \
		--username $(AWS_ECR_USER) \
		--password-file $(HOME)/.hal/$(NAME)-ecr-pass.txt \
		--address $(AWS_ECR_REGISTRY) || true
	$(hal) config provider docker-registry enable

ifndef $(SLACK_TOKEN)
	$(hal) config notification slack disable
else
	echo $(SLACK_TOKEN) | \
		$(hal) config notification slack edit \
			--bot-name spinnaker \
			--token
	$(hal) config notification slack enable
endif
	$(hal) config provider kubernetes account delete $(K8S_ACCOUNT_NAME) || true
	$(hal) config provider kubernetes account add $(K8S_ACCOUNT_NAME) \
		--docker-registries aws-ecr-$(AWS_DEFAULT_REGION) \
		--context $(DOMAIN_NAME)
	$(hal) config provider kubernetes enable

	$(hal) config storage s3 edit \
		--region $(AWS_DEFAULT_REGION) \
		--root-folder /spinnaker \
		--bucket $(AWS_S3_BUCKET) \
		--assume-role role/$(AWS_ASSUME_ROLE) \

	$(hal) config ci jenkins master delete $(JENKINS_FQDN) || true
	@echo $(JENKINS_PASSWORD) | \
		$(hal) config ci jenkins master add $(JENKINS_FQDN) \
			--no-validate \
			--address $(JENKINS_ADDRESS) \
			--username $(JENKINS_USER) \
			--password
	$(hal) config ci jenkins enable
.PHONY: configure

deploy: tf_init tf_plan tf_apply configure
	$(hal) config security ui  edit --override-base-url $(INGRESS_PROTOCOL)://$(COMPONENT_NAME).$(INGRESS_FQDN)
	$(hal) config security api edit --override-base-url $(INGRESS_PROTOCOL)://api.$(COMPONENT_NAME).$(INGRESS_FQDN)
	$(hal) config storage edit --type redis
	$(hal) config storage edit --type s3
	$(hal) config deploy edit \
		--account-name kubernetes \
		--type distributed
	$(hal) deploy apply
	-$(hal) backup create

	$(kubectl) apply -f ingress.yaml

	-tar cf - -C $(HOME)/.hal . | \
		aws --region=$(STATE_REGION) s3 cp - s3://$(STATE_BUCKET)/$(DOMAIN_NAME)/spinnaker/$(COMPONENT_NAME)/halbackup-0.tar
	-aws --region=$(STATE_REGION) s3 cp $(HOME)/halbackup*.tar s3://$(STATE_BUCKET)/$(DOMAIN_NAME)/spinnaker/$(COMPONENT_NAME)/
.PHONY: deploy

undeploy:
	-$(kubectl) delete -f ingress.yaml
	-$(kubectl) delete namespace "$(NAMESPACE)"
	@echo Undeploying IAM role
	$(MAKE) tf_destroy
.PHONY: undeploy

clean:
	rm -rf .terraform/$(DOMAIN_NAME)*
	rm -rf $(HOME)/.hal/$(NAME)
