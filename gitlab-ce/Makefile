.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export SPINNAKER_NAMESPACE ?= spinnaker
export DOMAIN_NAME         ?= default 
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(SPINNAKER_NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

check:
	if [ ! $(which helm) ]; then \
		echo "ERROR - Helm is not installed"; \
		exit 1; \
	fi

#verify that the tiller service is running, init it if needed
init: check
	if [[ $($(helm) version) -ne 0 ]]; then \
		mkdir -p $(HELM_HOME); \
		$(helm) init --client-only --upgrade; \
		for i in $$(seq 1 12); do \
			if $(helm) version; then \
				exit 0; \
			fi; \
			echo "Waiting for Tiller pod is up and running ($$i)..."; \
			sleep 10; \
		done; \
		echo "Timeout waiting for Tiller" \
		exit 1; \
	fi;

deploy: init
	./init_values.sh
	$(helm) install --name gitlab-ce -f values.yaml ./
.PHONY: deploy

undeploy:
	$(helm) delete --name gitlab-ce
.PHONY: undeploy
