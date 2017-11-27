
.DEFAULT_GOAL := deploy

export HELM_HOME      ?= $(shell pwd)/.helm
export NAMESPACE	  ?= gitlab
export COMPONENT_NAME ?= gitlab
export DOMAIN_NAME    ?= default
export kubectl        ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm           ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
export kind           ?= aws

deploy: clean init fetch install output
	bash -e ./deploy-$(kind).sh
	# $(kubectl) apply --namespace $(NAMESPACE) -f ingress.yaml
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@$(helm) init --client-only --upgrade
	@mkdir -p charts

fetch:
	$(helm) fetch \
		--destination charts \
		--untar stable/gitlab-ce
.PHONY: fetch

install:
	# we don't use helm's postgres, we use our own component
	rm -rf charts/gitlab-ce/charts/postgresql
	@cp secrets.yaml      charts/gitlab-ce/templates/
	@cp deployment.yaml   charts/gitlab-ce/templates/
	@cp svc.yaml          charts/gitlab-ce/templates/
	@cp configmap.yaml    charts/gitlab-ce/templates/
	@cp requirements.yaml charts/gitlab-ce/
	@rm charts/gitlab-ce/requirements.lock
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' || \
		$(helm) install charts/gitlab-ce \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--replace \
			--values values.yaml

.PHONY: install

undeploy: init
	bash -e ./undeploy-$(kind).sh
	$(helm) list -q | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
.PHONY: undeploy

output:
	@echo Outputs:
	@echo git_fqdn=git.$(DOMAIN_NAME)
	@echo

clean:
	@rm -rf $(HELM_HOME)
	@rm -rf charts
