.DEFAULT_GOAL := deploy

export EXTERNAL_SERVICE_NAME := external-$(COMPONENT_NAME)
export TF_DATA_DIR         := .terraform

kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
jq := jq -cM
terraform   ?= terraform-v0.11

TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan
TIMEOUT     ?= 600

deploy: k8s_resources wait_nlb init plan apply

k8s_resources:
	$(kubectl) apply -f ../templates/deployment.yaml
	$(kubectl) apply -f ../templates/service.yaml

rm_k8s:
	$(kubectl) delete -f ../templates/deployment.yaml
	$(kubectl) delete -f ../templates/service.yaml

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

undeploy: init destroy apply rm_k8s

wait_nlb:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval get_svc=$(kubectl) get --output=json service $(EXTERNAL_SERVICE_NAME))
	@ echo 'Waiting for $(EXTERNAL_SERVICE_NAME) service elb'
	@ while [ `date +%s` -le "$(timeout)" ]; do \
		if [ `$(get_svc) | $(jq) '.status.loadBalancer.ingress' | xargs` != "null" ]; then \
			printf ' done\n---\n'; \
			$(get_svc) | jq .status.loadBalancer;\
			test `$(get_svc) | $(jq) '.status.loadBalancer.ingress' | xargs` != "null" && exit 0; \
		fi; \
		printf "."; \
		sleep 2; \
	done; \
	echo " ERROR timeout $(TIMEOUT)sec"; \
	exit 1

