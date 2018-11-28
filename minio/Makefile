.DEFAULT_GOAL := deploy

export HELM_HOME ?= $(shell pwd)/.helm

COMPONENT_NAME ?= minio
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= minio
INGRESS_DOMAIN ?= localhost
PROTOCOL       ?= http
CLOUD          ?= aws
ALIAS          ?= $(COMPONENT_NAME)

# hardcoded in helm chart
SECRET         := $(COMPONENT_NAME)-$(NAMESPACE)-minio
ACCESS_KEY_REF ?= accesskey
SECRET_KEY_REF ?= secretkey

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
jq      ?= jq -Ms

CHART_VERSION    ?= 1.6.4

ifeq ($(PROTOCOL),https)
mc ?= mc --no-color
else
mc ?= mc --insecure --no-color
endif

ARCH ?= $(shell uname -s | tr '[:upper:]' '[:lower:]')
ifeq ($(ARCH),darwin)
	base64_decode = base64 --decode
else
	base64_decode = base64 -d
endif

ifeq ($(ACCESS_KEY),)
	secret_val := $(shell $(kubectl) get secret '$(SECRET)' -o json | jq -r '.data?.$(ACCESS_KEY_REF)' | $(base64_decode))
	random     := $(shell uuidgen | tr ' [:upper:] ' ' [:lower:] ' | tr -d '-')
	ACCESS_KEY := $(or $(secret_val),$(random))
endif

ifeq ($(SECRET_KEY),)
	secret_val := $(shell $(kubectl) get secret '$(SECRET)' -o json | jq -r '.data?.$(SECRET_KEY_REF)' | $(base64_decode))
	random     := $(shell uuidgen | tr ' [:upper:] ' ' [:lower:] ' | tr -d '-')
	SECRET_KEY := $(or $(secret_val),$(random))
endif

deploy: clean init fetch purge install configure

init:
	mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade --wait

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/minio \
		--version $(CHART_VERSION)

namespace:
	- $(kubectl) create namespace $(NAMESPACE)

$(CLOUD)-storage-class:
	- $(kubectl) create -f $@.yaml
.PHONY: $(CLOUD)-storage-class

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install: namespace $(CLOUD)-storage-class
	@ echo Running helm install charts/minio...
	@ $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/minio \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait \
			--values values.yaml \
			--set 'accessKey=$(ACCESS_KEY)' \
			--set 'secretKey=$(SECRET_KEY)'

configure:
	@ $(mc) config host add $(ALIAS) \
		$(PROTOCOL)://$(COMPONENT_NAME).$(INGRESS_DOMAIN) \
		$(ACCESS_KEY) $(SECRET_KEY) \
		S3v4
	@ $(mc) config host list

unconfigure:
	- $(mc) config host rm $(ALIAS)

undeploy: init unconfigure
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	- $(kubectl) delete pvc $(COMPONENT_NAME)
	- $(kubectl) delete job $(COMPONENT_NAME)-make-bucket-job

clean:
	rm -rf $(HELM_HOME) charts

output:
	@ echo
	@ echo Outputs:
	@ echo secret_name = $(SECRET)
	@ echo secret_namespace = $(NAMESPACE)

-include ../Mk/phonies
