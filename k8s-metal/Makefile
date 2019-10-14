.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= k8s-metal
DOMAIN_NAME    ?= cluster1.metal.dev.superhub.io
NAME           ?= setme
API_ENDPOINT   ?= 10.0.10.20:6443
API_HOST       := $(shell echo $(API_ENDPOINT) | cut -d: -f1)
API_PORT       := $(shell echo $(API_ENDPOINT) | cut -d: -f2)
$(if $(API_PORT),,API_PORT:=443)

kubectl   ?= kubectl --kubeconfig=./kubeconfig --insecure-skip-tls-verify=true

deploy: storage output

storage:
	$(kubectl) apply -f storage-class.yaml
.PHONY: storage

output:
	@echo
	@echo Outputs:
	@echo dns_domain = $(DOMAIN_NAME)
# if endpoint is not an IP then output it as is, else output api.domain:port
	@echo api_endpoint = $(if $(shell echo $(API_ENDPOINT) | sed -e 's/[0-9.:]//g'),$(API_ENDPOINT),api.$(DOMAIN_NAME):$(API_PORT))
	@echo

undeploy:


-include ../Mk/phonies
