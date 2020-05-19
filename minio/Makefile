.DEFAULT_GOAL := deploy

export HELM_HOME ?= $(shell pwd)/.helm

COMPONENT_NAME ?= minio
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= minio
INGRESS_DOMAIN ?= localhost
PROTOCOL       ?= http
ALIAS          ?= $(COMPONENT_NAME)
DOMAIN         ?= minio
WAIT_TIMEOUT   ?= 180
DEFAULT_BUCKET ?= default

# secret-name has been driven by fullnameOverride in helm chart
SECRET         := $(COMPONENT_NAME)
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

ifeq ($(ACCESS_KEY),)
	secret_val := $(shell $(kubectl) get secret '$(SECRET)' -o json | jq -r '.data?.$(ACCESS_KEY_REF)' | base64 -d))
	random     := $(shell uuidgen | tr ' [:upper:] ' ' [:lower:] ' | tr -d '-')
	ACCESS_KEY := $(or $(secret_val),$(random))
endif

ifeq ($(SECRET_KEY),)
	secret_val := $(shell $(kubectl) get secret '$(SECRET)' -o json | jq -r '.data?.$(SECRET_KEY_REF)' | base64 -d))
	random     := $(shell uuidgen | tr ' [:upper:] ' ' [:lower:] ' | tr -d '-')
	SECRET_KEY := $(or $(secret_val),$(random))
endif

ifeq ($(NATS_ENABLED),true)
	MINIO_NOTIFICATIONS += nats-notifications
endif

HELM_OPTS := --values values.yaml
HELM_OPTS += --set 'accessKey=$(ACCESS_KEY)'
HELM_OPTS += --set 'secretKey=$(SECRET_KEY)'
HELM_OPTS += --set 'fullnameOverride=$(SECRET)'

ifneq ($(TLS_KIND),)
HELM_OPTS += --values $(TLS_KIND)/values.yaml
endif

deploy: clean init fetch purge install configure $(MINIO_NOTIFICATIONS) output

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

wait:
	sleep 10

HOST_CMD := host
PING_CMD := $(HOST_CMD) $(COMPONENT_NAME).$(INGRESS_DOMAIN)
wait-dns:
	$(eval timeout        := $(shell echo "`date +%s` + $(WAIT_TIMEOUT)" | bc ))
	@ echo "Waiting for DNS to resolve $(COMPONENT_NAME).$(INGRESS_DOMAIN) with $(HOST_CMD)"
	$(eval current_time   := date +%s)
	while [ `$(current_time)` -le "$(timeout)" ]; do \
		if $(PING_CMD); then \
			echo "Done!"; \
			exit 0; \
		fi;  \
		echo "Still waiting..."; \
		sleep 8; \
	done; \
	echo "ERROR timeout $(WAIT_TIMEOUT)sec"; \
	exit 1;


nats-notifications: wait-dns
	$(mc) --insecure event add $(ALIAS)/$(DEFAULT_BUCKET) arn:minio:sqs:us-east-1:1:nats

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install: namespace
	@ echo Running helm install charts/minio...
	@ $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/minio $(HELM_OPTS) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait

configure: wait-dns
	@ $(mc) --insecure config host add $(ALIAS) \
		$(PROTOCOL)://$(COMPONENT_NAME).$(INGRESS_DOMAIN) \
		$(ACCESS_KEY) $(SECRET_KEY) \
		--api S3v4
	@ $(mc) --insecure config host list

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
	@ echo secret = $(SECRET)
	@ echo

-include ../Mk/phonies
