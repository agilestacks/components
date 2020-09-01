.DEFAULT_GOAL := deploy

export HELM_HOME ?= $(shell pwd)/.helm

COMPONENT_NAME ?= minio
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= minio
INGRESS_DOMAIN ?= localhost
PROTOCOL       ?= http
ALIAS          ?= $(COMPONENT_NAME)
DOMAIN         ?= minio
DEFAULT_BUCKET ?= default

# secret-name has been driven by fullnameOverride in helm chart
SECRET         := $(COMPONENT_NAME)
MINIO_ACCESS_KEY_REF ?= accesskey
MINIO_SECRET_KEY_REF ?= secretkey

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
jq      ?= jq -Ms

CHART_VERSION    ?= 1.6.4

ifeq ($(PROTOCOL),https)
mc ?= mc --no-color
else
mc ?= mc --insecure --no-color
endif

ifeq ($(MINIO_ACCESS_KEY),)
	secret_val := $(shell $(kubectl) get secret '$(SECRET)' -o json | jq -r '.data?.$(MINIO_ACCESS_KEY_REF)' | base64 -d)
	random     := $(shell uuidgen | tr ' [:upper:] ' ' [:lower:] ' | tr -d '-')
	MINIO_ACCESS_KEY := $(or $(secret_val),$(random))
endif

ifeq ($(MINIO_SECRET_KEY),)
	secret_val := $(shell $(kubectl) get secret '$(SECRET)' -o json | jq -r '.data?.$(MINIO_SECRET_KEY_REF)' | base64 -d)
	random     := $(shell uuidgen | tr ' [:upper:] ' ' [:lower:] ' | tr -d '-')
	MINIO_SECRET_KEY := $(or $(secret_val),$(random))
endif


ifeq ($(NATS_ENABLED),true)
	MINIO_NOTIFICATIONS += nats-notifications
endif

HELM_OPTS := --values charts/minio/values.yaml
HELM_OPTS := --values values.yaml
HELM_OPTS += --set 'accessKey=$(MINIO_ACCESS_KEY)'
HELM_OPTS += --set 'secretKey=$(MINIO_SECRET_KEY)'
HELM_OPTS += --set 'fullnameOverride=$(SECRET)'

ifneq ($(TLS_KIND),)
HELM_OPTS += --values $(TLS_KIND)/values.yaml
endif

deploy: clean init fetch purge install output wait-dns
ifneq (,$(filter tls-ingress,$(HUB_PROVIDES)))
wait-tls: ENDPOINT:=$(COMPONENT_NAME).$(INGRESS_DOMAIN)
wait-tls: TIMEOUT:=$(shell echo "`date +%s` + 600" | bc )
wait-tls:
	@ echo "Waiting for valid TLS for $(ENDPOINT):"
	while [ `date +%s` -le "$(TIMEOUT)" ]; do \
		if ! (openssl s_client -connect $(ENDPOINT):443 \
			-servername $($(ENDPOINT) ) </dev/null \
			| openssl x509 -in /dev/stdin -noout) 2>&1 | grep -q 'verify error'; then \
			echo "Done!"; \
			exit 0; \
		fi;  \
		echo "Still waiting..."; \
		sleep 8; \
	done; \
	echo "Error: timed out"; \
	exit 1;
deploy: wait-tls
endif

init:
	mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade --wait

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/minio \
		--version $(CHART_VERSION)

namespace:
	$(kubectl) get namespace $(NAMESPACE) || \
		$(kubectl) create namespace $(NAMESPACE)

wait:
	sleep 10

wait-dns: ENDPOINT:=$(COMPONENT_NAME).$(INGRESS_DOMAIN).
wait-dns: TIMEOUT:=$(shell echo "`date +%s` + 600" | bc )
wait-dns:
	@ echo "Waiting for DNS to resolve $(ENDPOINT):"
	while [ `date +%s` -le "$(TIMEOUT)" ]; do \
		if nslookup $(ENDPOINT) > /dev/null; then \
			echo "Done!"; \
			exit 0; \
		fi;  \
		echo "Still waiting..."; \
		sleep 8; \
	done; \
	echo "Error: timed out"; \
	exit 1;

# nats-notifications: wait-dns
# 	$(mc) --insecure event list $(ALIAS)/$(DEFAULT_BUCKET) | grep arn:minio:sqs::1:nats  || \
#             $(mc) --insecure event add $(ALIAS)/$(DEFAULT_BUCKET) arn:minio:sqs:us-east-1:1:nats

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

install: namespace
	@ echo Running helm install charts/minio...
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/minio $(HELM_OPTS) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--wait

# configure: wait-dns
# 	@ $(mc) --insecure config host add $(ALIAS) \
# 		$(PROTOCOL)://$(COMPONENT_NAME).$(INGRESS_DOMAIN) \
# 		$(MINIO_ACCESS_KEY) $(MINIO_SECRET_KEY) \
# 		--api S3v4
# 	@ $(mc) --insecure config host list

# unconfigure:
# 	- $(mc) config host rm $(ALIAS)

undeploy: init
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	# TODO: implement pv cleanup
	$(kubectl) delete job $(COMPONENT_NAME)-make-bucket-job
	kubectl --context="$(DOMAIN_NAME)" patch pvc $(COMPONENT_NAME) -p '{"metadata":{"finalizers":null}}'
	kubectl --context="$(DOMAIN_NAME)" delete pvc --force $(COMPONENT_NAME)

clean:
	rm -rf $(HELM_HOME) charts

output:
	@ echo
	@ echo Outputs:
	@ echo secret = $(SECRET)
	@ echo

-include ../Mk/phonies

.IGNORE: undeploy
.SILENT: output install wait-dns wait-tls init
