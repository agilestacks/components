.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   	 ?= etcd
export COMPONENT_NAME      ?= etcd-operator
export DOMAIN_NAME         ?= default 
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"


deploy: clean init fetch wait install output
	# $(kubectl) apply --namespace $(NAMESPACE) -f ingress.yaml
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade
	@mkdir -p charts

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


fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/etcd-operator
.PHONY: fetch

install:
	$(helm) install charts/etcd-operator \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--replace \
		--values values.yaml
	$(helm) upgrade charts/etcd-operator \
		--set cluster.enabled=true \
		--namespace $(NAMESPACE) \
		$(COMPONENT_NAME) \
		stable/etcd-operator
.PHONY: install

undeploy: init
	$(kubectl) get --namespace $(NAMESPACE) cluster/$(COMPONENT_NAME) -o=yaml|$(kubectl) delete -f -
	$(helm) delete $(COMPONENT_NAME)
	# $(helm) undeploy -f hub.component
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts

output:
	@echo Outputs:
.PHONY: output
