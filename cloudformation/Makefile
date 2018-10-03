.DEFAULT_GOAL := deploy

export NAME ?= example

export AWS_PROFILE        ?= default
export AWS_DEFAULT_REGION ?= us-east-2

aws := aws

cloudformation-deploy:
	$(aws) cloudformation deploy --stack-name $(NAME) \
		$(CLOUDFORMATION_DEPLOY_OPTS) \
		--template-file cloudformation.yaml \
		--parameter-overrides BucketDescription=$(NAME)

deploy: CLOUDFORMATION_DEPLOY_OPTS:=--no-fail-on-empty-changeset
deploy: cloudformation-deploy
	$(eval OUT := $(shell mktemp))
	$(aws) cloudformation describe-stacks --stack-name $(NAME) | tee $(OUT)
	@echo Outputs:
	@jq -r '.Stacks[0].Outputs[] | .OutputKey + " = " + .OutputValue' $(OUT)
	@echo
	-@rm $(OUT)
.PHONY: deploy

changeset: CLOUDFORMATION_DEPLOY_OPTS:=--no-execute-changeset
changeset: cloudformation-deploy
.PHONY: changeset

undeploy:
	$(aws) cloudformation delete-stack --stack-name $(NAME)
	$(aws) cloudformation wait stack-delete-complete --stack-name $(NAME)
.PHONY: undeploy
