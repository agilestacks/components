.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= prometheus
export COMPONENT_NAME      ?= prometheus
export DOMAIN_NAME         ?= default
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"


deploy: clean init wait install_operator install output
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade


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

wait_tpr:
	@for i in $$(seq 1 60); do \
		if $(kubectl) get thirdpartyresources/cluster.etcd.coreos.com; then \
			sleep 5; \
			exit 0; \
		fi; \
		echo "Waiting for thirdpartyresource/cluster.etcd.coreos.com to be deployed ($$i)..."; \
		sleep 20; \
	done; \
	echo "Timeout waiting for thirdpartyresource to be deployed" \
	exit 1

install_operator:
ifeq ($(findstring $(COMPONENT_NAME)-operator, $(shell $(helm) list -q | xargs)),)
	$(helm) install charts/prometheus-operator \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--replace \
		--wait \
		--values values-operator.yaml
endif
.PHONY: install_operator

install:
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),)
	$(helm) install charts/prometheus \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--replace \
		--wait \
		--values values-prometheus.yaml
endif
.PHONY: install




undeploy: init
	$(kubectl) get --namespace $(NAMESPACE) cluster/$(COMPONENT_NAME) -o=yaml|$(kubectl) delete -f - || true
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),$(COMPONENT_NAME))
	$(helm) delete --purge $(COMPONENT_NAME)
endif
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)

output:
	@echo Outputs:
	@echo prometheus=http://$(COMPONENT_NAME).$(NAMESPACE).svc.cluster.local:9090
	@echo
	@echo Prometheus has been installed successfully.
.PHONY: output

