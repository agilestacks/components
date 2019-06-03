.DEFAULT_GOAL := deploy

export TF_VAR_domain       := $(DOMAIN_NAME)
export TF_VAR_service_name := $(COMPONENT_NAME)
export TF_VAR_namespace    := $(NAMESPACE)
export TF_VAR_record       := $(COMPONENT_NAME).svc
export TF_DATA_DIR         := .terraform

kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
jq := jq -cM
terraform   ?= terraform-v0.11

TF_CLI_ARGS ?= -no-color -input=false
TFPLAN      := $(TF_DATA_DIR)/terraform.tfplan

TIMEOUT     ?= 600

DRYRUN := $(shell $(kubectl) patch service $(COMPONENT_NAME) --patch "$$(cat nginx-service.yaml)" --dry-run)
ifeq (,$(findstring "no change","$(DRYRUN)"))
patch_service:
	$(kubectl) patch service $(COMPONENT_NAME) --patch "$$(cat nginx-service.yaml)"
	$(kubectl) get service $(COMPONENT_NAME) -o json \
		| $(jq) 'del(.status, .metadata.uid, .metadata.resourceVersion, .metadata.selfLink, .metadata.creationTimestamp, .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration")' \
		| $(kubectl) replace --wait --force -f -

DEPLOY_PREREQS += patch_service
endif
DEPLOY_PREREQS += wait_elb init plan apply $(PULL_SECRET)

deploy: $(DEPLOY_PREREQS)

$(TF_DATA_DIR):
	@rm -rf $@ && mkdir -p $@

init: $(TF_DATA_DIR)
	$(terraform) init -get=true -force-copy $(TF_CLI_ARGS) \
        -backend=true -reconfigure \
        -backend-config="bucket=$(STATE_BUCKET)" \
        -backend-config="region=$(STATE_REGION)" \
        -backend-config="key=$(DOMAIN_NAME)/harbor/$(COMPONENT_NAME)/terraform.tfstate" \
        -backend-config="profile=$(AWS_PROFILE)"

plan:
	$(terraform) plan $(TF_CLI_ARGS) -refresh=true -module-depth=-1 -out=$(TFPLAN)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -auto-approve $(TFPLAN)

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

undeploy: init destroy apply delete-$(PULL_SECRET)

wait_elb:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval get_svc=$(kubectl) get --output=json service $(COMPONENT_NAME))
	@ echo 'Waiting for $(COMPONENT_NAME) service elb'
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

$(PULL_SECRET):
	- $(kubectl) create secret docker-registry $(PULL_SECRET) \
		--docker-server=$(TF_VAR_record).$(DOMAIN_NAME) \
		--docker-username=$(ADMIN_USERNAME) \
		--docker-password="$$ADMIN_PASSWORD"

delete-$(PULL_SECRET):
	- $(kubectl) delete secret $(PULL_SECRET)
