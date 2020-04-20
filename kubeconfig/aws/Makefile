.DEFAULT_GOAL := deploy
KUBECONFIG    ?= $(error KUBECONFIG has not beens defined)
S3_URL        ?= $(error S3_URL has not been defined)
ACL           ?= private
aws           := aws --profile "$(AWS_PROFILE)" --region "$(AWS_REGION)"

$(S3_URL):
	$(aws) s3 cp --acl $(ACL) $(KUBECONFIG) $@

deploy: $(S3_URL)
undeploy:
	- $(aws) s3 rm "$(S3_URL)"

.PHONY: $(S3_URL) deploy undeploy
