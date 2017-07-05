.DEFAULT_GOAL := build

IMAGE_NAME   			 ?= $(notdir $(abspath .))
VERSION      			 ?= latest
DOCKER_IMAGE 			 ?= $(IMAGE_NAME):$(VERSION)
AWS_DEFAULT_REGION ?= us-east-1

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
	aws ecr get-login --region us-east-2 | sed -e 's/[ +]-e[ +]none[ +]/ /g' | sh -
	docker push $(DOCKER_IMAGE)
.PHONY: push

deploy: build push output

undeploy: 
	echo "do nothing"

output:
	echo image_name=$(DOCKER_IMAGE)
.PHONY: output