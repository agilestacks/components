.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= sagemaker
NAME ?= SageBuild

export AWS_DEFAULT_REGION ?= us-east-2

aws := aws

cloudformation-deploy:
	$(aws) cloudformation deploy --stack-name $(NAME) \
	  --s3-bucket $(STATE_BUCKET) \
		--region $(STATE_REGION) \
		--capabilities CAPABILITY_NAMED_IAM \
		$(CLOUDFORMATION_DEPLOY_OPTS) \
		--template-file cloudformation.yaml \
		--parameter-overrides BucketDescription=$(NAME) ConfigFramework=$(CONFIG_FRAMEWORK) NoteBookInstanceType=$(NOTEBOOK_INSTANCE_TYPE) ExternalGithubRepo=$(EXTERNAL_GITHUB_REPO)
.PHONY: cloudformation-deploy

deploy: CLOUDFORMATION_DEPLOY_OPTS:=--no-fail-on-empty-changeset
deploy: cloudformation-deploy
	$(eval OUT := $(shell mktemp))
	$(aws) --output json cloudformation describe-stacks --stack-name $(NAME) | tee $(OUT)
	@echo Outputs:
	@jq -r '.Stacks[0].Outputs[] | .OutputKey + " = " + .OutputValue' $(OUT)
	@echo
	-@rm $(OUT)

changeset: CLOUDFORMATION_DEPLOY_OPTS:=--no-execute-changeset
changeset: cloudformation-deploy
.PHONY: changeset

undeploy:
	$(aws) cloudformation delete-stack --stack-name $(NAME)
	$(aws) cloudformation wait stack-delete-complete --stack-name $(NAME)

-include ../Mk/phonies
