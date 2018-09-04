.DEFAULT_GOAL := deploy

ENDPOINT    ?= localhost:9000
SECRET_NAME ?= minio

deploy: output

undeploy:
	@ echo "Argo has nothing to undeploy for minio"
.PHONY: undeploy

output:
	@ echo
	@ echo Outputs:
	@ echo secret_name = $(SECRET_NAME)
	@ echo endpoint = $(ENDPOINT)
	@ echo iam_user_name =
	@ echo iam_user_arn =
	@ echo
.PHONY: output
