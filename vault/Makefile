.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   	 ?= vault
export COMPONENT_NAME      ?= vault-service
export DOMAIN_NAME         ?= default
export INGRESS_ENABLED	   ?= false
export ETCD_CLIENT_URL	   ?= "http://etcd-operator-client.etcd-operator.svc.cluster.local:2379"
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"


deploy: clean init wait install output
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade

install:
	$(helm) install vault \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--replace \
		--values values.yaml
.PHONY: install

undeploy: init
	$(helm) del --purge $(COMPONENT_NAME)
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts

output:
	@echo Outputs:
.PHONY: output

wait:
	@for i in $$(seq 1 60); do \
		if $(helm) version; then \
			exit 0; \
		fi; \
		echo "Waiting for Tiller pod is up and running ($$i)..."; \
		sleep 10; \
	done; \
	echo "Timeout waiting for Tiller" \
	exit 1