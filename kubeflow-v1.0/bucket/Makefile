unexport $(filter AWS_%,$(.VARIABLES))

ifneq (,$(HUB_S3_ACCESS_KEY))
export AWS_ACCESS_KEY_ID := $(HUB_S3_ACCESS_KEY)
endif

ifneq (,$(HUB_S3_SECRET_KEY))
export AWS_SECRET_ACCESS_KEY := $(HUB_S3_SECRET_KEY)
endif

aws := aws
ifneq (,$(HUB_S3_REGION))
export AWS_REGION := $(HUB_S3_REGION)
aws += --region="$(HUB_S3_REGION)"
endif

ifneq (,$(HUB_S3_ENDPOINT))
aws += --endpoint-url="$(HUB_S3_ENDPOINT)" --no-verify-ssl
endif

deploy:
	$(aws) s3api head-bucket --bucket="$(HUB_S3_BUCKET)" 2>/dev/null || \
		$(aws) s3api create-bucket --bucket="$(HUB_S3_BUCKET)" \
		--create-bucket-configuration LocationConstraint=$(AWS_REGION)
		--acl="private"

undeploy:
	@ echo "not yet implemented"
