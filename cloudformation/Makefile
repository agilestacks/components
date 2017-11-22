.DEFAULT_GOAL := deploy

export NAME ?= example

export AWS_PROFILE        ?= default
export AWS_DEFAULT_REGION ?= us-east-2

aws := aws

deploy:
	$(eval OUT = $(shell mktemp))
	$(aws) cloudformation create-stack --stack-name $(NAME) \
		--template-body file://cloudformation.yaml \
		--parameters ParameterKey=BucketDescription,ParameterValue=$(NAME)
	$(aws) cloudformation wait stack-create-complete --stack-name $(NAME)
	$(aws) cloudformation describe-stacks --stack-name $(NAME) | tee $(OUT)
	@echo Outputs:
	@jq -r '.Stacks[0].Outputs[] | select (.OutputKey == "S3BucketName") | "s3_bucket_name = " + .OutputValue' $(OUT)
	@echo
	-@rm $(OUT)
.PHONY: deploy

undeploy:
	$(aws) cloudformation delete-stack --stack-name $(NAME)
	$(aws) cloudformation wait stack-delete-complete --stack-name $(NAME)
.PHONY: undeploy
