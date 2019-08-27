.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= k8s-metal
DOMAIN_NAME    ?= $(CUSTOM_INGRESS_DOMAIN)
NAME           := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
BASE_DOMAIN    := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)
API_ENDPOINT   ?=
API_HOST       := $(shell echo $(API_ENDPOINT) | cut -d: -f1)
API_PORT       := $(shell echo $(API_ENDPOINT) | cut -d: -f2)
$(if $(API_PORT),,API_PORT:=443)

STATE_BUCKET   ?= terraform.agilestacks.com
STATE_REGION   ?= us-east-1

export CUSTOM_INGRESS_NAME := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
export CUSTOM_INGRESS_BASE := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)

export AWS_DEFAULT_REGION ?= us-east-2

kubectl   ?= kubectl --kubeconfig=./kubeconfig --insecure-skip-tls-verify=true

deploy: storage output

storage:
	$(kubectl) apply -f storage-class.yaml
.PHONY: storage

output:
	@echo
	@echo Outputs:
	@echo dns_name = $(NAME)
	@echo dns_base_domain = $(BASE_DOMAIN)
# if endpoint is not an IP then output it as is, else output api.domain:port
	@echo api_endpoint = $(if $(shell echo $(API_ENDPOINT) | sed -e 's/[0-9.:]//g'),$(API_ENDPOINT),api.$(DOMAIN_NAME):$(API_PORT))
	@echo

undeploy:
	$(shell echo "no-op")

-include ../Mk/phonies
