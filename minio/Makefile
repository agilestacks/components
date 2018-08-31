.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export COMPONENT_NAME      ?= minio
export NAMESPACE           ?= minio
export DOMAIN_NAME         ?= default
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch install
	$(kubectl) apply -f namespace.yaml
.PHONY: deploy

init:
	mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade --wait
	@mkdir -p tmp

fetch:
	$(helm) fetch \
            --destination charts \
            --untar stable/minio
.PHONY: fetch

install:
	# cp config-json.yaml charts/minio/templates
	# cp deployment.yaml charts/minio/templates
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
        $(helm) install charts/minio \
            --name $(COMPONENT_NAME) \
            --namespace $(NAMESPACE) \
            --replace \
            --wait \
            --values Values.yaml
.PHONY: install

# presently this is disabled.
# We're assuming that the creation of a minio bucket and a minio-event
# listener is the responsibility of the consumer of the events
post_install:
	./create_bucket_listener.sh
.PHONY: install

undeploy: init
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
        $(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

clean:
	rm -rf $(HELM_HOME)
	rm -rf tmp

