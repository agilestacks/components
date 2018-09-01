.DEFAULT_GOAL := deploy

export HELM_HOME ?= $(shell pwd)/.helm
COMPONENT_NAME   ?= minio
NAMESPACE        ?= minio
DOMAIN_NAME      ?= default
INGRESS_DOMAIN	 ?= localhost
PROTOCOL 		 ?= http
CLOUD 			 ?= aws
ALIAS            ?= $(COMPONENT_NAME)

kubectl 		 ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm 			 ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

ifeq ($(PROTOCOL),https)
mc ?= mc --no-color
else
mc ?= mc --insecure --no-color
endif

ifeq ($(ACCESS_KEY),)
ACCESS_KEY := $(shell uuidgen | tr ' [:upper:] ' ' [:lower:] ' | tr -d '-')
endif

ifeq ($(SECRET_KEY),)
SECRET_KEY := $(shell uuidgen | tr ' [:upper:] ' ' [:lower:] ' | tr -d '-')
endif

deploy: clean init fetch install configure

init:
	mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade --wait
	@mkdir -p tmp

fetch:
	$(helm) fetch \
            --destination charts \
            --untar stable/minio
.PHONY: fetch

namespace:
	- $(kubectl) create namespace $(NAMESPACE)
.PHONY: namespace

$(CLOUD)-storage-class:
	kubectl apply -f $@.yaml
.PHONY: $(CLOUD)-storage-class

install: namespace $(CLOUD)-storage-class
	@ echo Running helm install charts/minio...
	@ $(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
        $(helm) install charts/minio \
            --name $(COMPONENT_NAME) \
            --namespace $(NAMESPACE) \
            --replace \
            --wait \
            --values Values.yaml \
            --set 'accessKey=$(ACCESS_KEY)' \
            --set 'secretKey=$(SECRET_KEY)'
.PHONY: install

configure:
	@ $(mc) config host add $(ALIAS) \
		$(PROTOCOL)://$(COMPONENT_NAME).$(INGRESS_DOMAIN) \
		$(ACCESS_KEY) $(SECRET_KEY) \
		S3v4
	@ $(mc) config host list
.PHONY: configure

unconfigure:
	- $(mc) config host rm $(ALIAS)
.PHONY: configure

# presently this is disabled.
# We're assuming that the creation of a minio bucket and a minio-event
# listener is the responsibility of the consumer of the events
post_install:
	./create_bucket_listener.sh
.PHONY: install

undeploy: init unconfigure
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
        $(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)
	rm -rf tmp

