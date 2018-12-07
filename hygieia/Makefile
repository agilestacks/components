.DEFAULT_GOAL := deploy

docker ?= docker

build: build-api build-ui

build-api:
	$(docker) build --rm --compress -t hygieia -f Dockerfile .
.PHONY: build-api

build-ui:
	$(docker) build --rm --compress -t hygieia -f Dockerfile.ui .
.PHONY: build-ui

deploy:
	@echo "deploying \`hygieia\`"
	@echo "\`hygieia\` is sucessfully deployed"
.PHONY: deploy

undeploy:
	@echo "undeploying \`hygieia\`"
	@echo "\`hygieia\` is sucessfully undeployed"
.PHONY: undeploy
