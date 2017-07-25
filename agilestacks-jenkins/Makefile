.DEFAULT_GOAL := build

IMAGE_NAME   			 ?= $(notdir $(abspath .))
VERSION      			 ?= latest
DOCKER_IMAGE 			 ?= $(IMAGE_NAME):$(VERSION)
AWS_DEFAULT_REGION ?= us-east-1
NAMESPACE          ?= automation-hub
export kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

build:
	docker build --no-cache --force-rm -t $(DOCKER_IMAGE) .
.PHONY: build

run:
	docker run --name=jenkins --env "JENKINS_OPTS=-Djenkins.slaves.JnlpSlaveAgentProtocol3.enabled=true" --rm -i -t -p 8080:8080 -p 50000:50000 -p 50001:50001 $(DOCKER_IMAGE)
.PHONY: run

attach:
	docker exec -i -t jenkins bash
.PHONY: run

push:
	aws ecr get-login --region $(AWS_DEFAULT_REGION) | sed -e 's/[ +]-e[ +]none[ +]/ /g' | sh -
	docker push $(DOCKER_IMAGE)
.PHONY: push

deploy: build push
	$(kubectl) apply -f config.yaml
	$(MAKE) output
.PHONY: deploy

undeploy: 
	$(kubectl) apply -f config.yaml
.PHONY: undeploy

output:
	@echo Outputs:
	@echo image_name=$(DOCKER_IMAGE)
	@echo Agile Stacks Jenkisn image pushed successfully
.PHONY: output