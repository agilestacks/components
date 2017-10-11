
.DEFAULT_GOAL := deploy

export HELM_HOME      ?= $(shell pwd)/.helm
export NAMESPACE	  ?= gitlab
export COMPONENT_NAME ?= gitlab-ce
export DOMAIN_NAME    ?= default
export kubectl        ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm           ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
export kind                ?= aws

deploy: clean init fetch wait install output
	bash -e ./deploy-$(kind).sh
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
		--untar stable/gitlab-ce
.PHONY: fetch

install:
	# we don't use helm's postgres, we use our own component
	rm -rf charts/gitlab-ce/charts/postgresql
	sh ./okta-app.sh -c create
	sh ./replace.sh
	@cp secrets.yaml      charts/gitlab-ce/templates/
	@cp deployment.yaml   charts/gitlab-ce/templates/
	@cp configmap.yaml    charts/gitlab-ce/templates/
	@cp requirements.yaml charts/gitlab-ce/
	@rm charts/gitlab-ce/requirements.lock
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),)
	$(helm) install charts/gitlab-ce \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--replace \
		--values values.yaml
endif

.PHONY: install

undeploy: init
	bash -e ./deploy-$(kind).sh
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),$(COMPONENT_NAME))
	$(helm) delete $(COMPONENT_NAME)
endif
.PHONY: undeploy

output:
	@echo Outputs:
	@echo git_fqdn=$(GIT_URL_PREFIX).$(DOMAIN_NAME)
	@echo

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts
