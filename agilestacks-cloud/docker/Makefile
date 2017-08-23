.DEFAULT_GOAL := deploy

export TF_VAR_name        ?= dev
export AWS_PROFILE        ?= default
export AWS_DEFAULT_REGION ?= us-east-2
export TF_VAR_base_domain ?= stacks.delivery
export TF_LOG             := debug
export TF_LOG_PATH        := .terraform/terraform.log
export TF_OPTS            ?= -no-color
export TF_UPDATE          ?= -update

export terraform          ?= terraform

export TF_VAR_backend_bucket ?= terraform.agilestacks.com
export TF_VAR_backend_region ?= us-east-1

export COMPONENT_NAME      	 ?= $(notdir $(abspath .))
export KIND       		     ?= creds

export REGISTRY           ?= $(subst https://,,$(lastword $(shell aws ecr get-login --region $(AWS_DEFAULT_REGION))))
export IMAGE              ?= $(REGISTRY)/agilestacks/$(TF_VAR_name).$(TF_VAR_base_domain)/cloud
export IMAGE_VERSION      ?= $(shell git rev-parse HEAD | colrm 7)
export DOCKER_BUILD_OTPS  ?= --no-cache  --force-rm

build:
	@docker build $(DOCKER_BUILD_OTPS) -t $(IMAGE):$(IMAGE_VERSION) .
.PHONY: build

push:
	aws ecr get-login --region $(AWS_DEFAULT_REGION) | sed -e 's/[ +]-e[ +]none[ +]/ /g' | sh -
	docker tag  $(IMAGE):$(IMAGE_VERSION) $(IMAGE):latest
	docker push $(IMAGE):$(IMAGE_VERSION)
	docker push $(IMAGE):latest
.PHONY: push

run:
	docker run --name=jenkins --env "JENKINS_OPTS=-Djenkins.slaves.JnlpSlaveAgentProtocol3.enabled=true" --rm -i -t -p 8080:8080 -p 50000:50000 -p 50001:50001 $(DOCKER_IMAGE)
	.PHONY: run

attach:
	docker exec -i -t jenkins bash
.PHONY: run

deploy: init plan apply output

init:
	@mkdir -p .terraform/$(TF_VAR_name).$(TF_VAR_base_domain)/.terraform
	@rm -rf .terraform/$(TF_VAR_name).$(TF_VAR_base_domain)/*
	$(terraform) init -get=true $(TF_CMD_OPTS) -force-copy  \
		-backend=true -input=false \
		-backend-config="bucket=$(TF_VAR_backend_bucket)" \
 		-backend-config="region=$(TF_VAR_backend_region)" \
 		-backend-config="key=$(COMPONENT_NAME)/$(TF_VAR_name).$(TF_VAR_base_domain)/terraform.tfstate" \
 		-backend-config="profile=$(AWS_PROFILE)" \
 		. .terraform/$(TF_VAR_name).$(TF_VAR_base_domain)
	$(MAKE) init_aws

init_aws:
	cp -f $(KIND).tf.ignore .terraform/$(TF_VAR_name).$(TF_VAR_base_domain)/$(KIND).tf

get:
	@cd .terraform/$(TF_VAR_name).$(TF_VAR_base_domain) && \
		$(terraform) get $(TF_UPDATE)
.PHONY: get

plan:
	@cd .terraform/$(TF_VAR_name).$(TF_VAR_base_domain) && \
	$(terraform) plan $(TF_OPTS) -refresh=true -module-depth=-1 -out=terraform.tfplan
.PHONY: plan

apply:
	@cd .terraform/$(TF_VAR_name).$(TF_VAR_base_domain) && \
	$(terraform) apply $(TF_OPTS) -Xshadow=false terraform.tfplan
.PHONY: apply

undeploy: init
	@cd .terraform/$(TF_VAR_name).$(TF_VAR_base_domain) && \
	$(terraform) plan $(TF_OPTS) -destroy -refresh=true -module-depth=-1 -out=terraform.tfplan
	$(MAKE) apply
.PHONY: undeploy_this

output:
	@cd .terraform/$(TF_VAR_name).$(TF_VAR_base_domain) && \
	$(terraform) output -json
.PHONY: output


clean:
	rm -rf .terraform/$(TF_VAR_name).$(TF_VAR_base_domain)
