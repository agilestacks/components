.DEFAULT_GOAL := deploy

docker ?= docker

build:
	$(docker) build --rm --compress -t hygieia .
.PHONY: build

deploy:
	@echo deploying \`hygieia\`
	@echo \`hygieia\` is sucessfully deployed

undeploy:
	@echo undeploying \`hygieia\`
	@echo \`hygieia\` is sucessfully undeployed


