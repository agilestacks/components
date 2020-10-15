.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= grafana
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= grafana
HELM_CHART     ?= grafana/grafana
CHART_VERSION  ?= 5.6.5

export HELM_HOME ?= $(shell pwd)/.helm

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

deploy: clean init fetch purge install output

# ACM terminates TLS on ELB
ifneq (acm,$(TLS_KIND))
# if ingress-tls is provided then tls-host-controler will manage TLS block for us
# else install our own TLS block
ifeq (,$(filter tls-ingress,$(HUB_PROVIDES)))
INGRESS_TLS_VALUES:=--values values-tls.yaml
endif
endif

ifneq (,$(POSTGRESQL_HOST))
POSTGRESQL_VALUES:=--values values-pg.yaml
deploy: pguser
endif

ifeq (true,$(OAUTH_ENABLED))
deploy: oidc
endif

init:
	@mkdir -p $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

fetch:
	$(helm) repo add grafana https://grafana.github.io/helm-charts
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(CHART_VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

# TODO hide GRAFANA_POSTGRESQL_USER password
pguser: psql:=$(kubectl) run psql-$(COMPONENT_NAME) -i --rm --image=postgres --restart=Never --env="PGPASSWORD=$$POSTGRESQL_ADMIN_PASSWORD" -- \
		psql -h $(POSTGRESQL_HOST) -p $(POSTGRESQL_PORT) -U $(POSTGRESQL_ADMIN_USER) $(POSTGRESQL_DATABASE)
pguser:
	-$(psql) -c " \
			revoke select on all tables in schema $(POSTGRESQL_SCHEMA) from \"$(GRAFANA_POSTGRESQL_USER)\"; \
			revoke usage on schema $(POSTGRESQL_SCHEMA) from \"$(GRAFANA_POSTGRESQL_USER)\"; \
			revoke usage on schema public from \"$(GRAFANA_POSTGRESQL_USER)\"; \
			drop user if exists \"$(GRAFANA_POSTGRESQL_USER)\";"
	$(psql) -c " \
			drop user if exists \"$(GRAFANA_POSTGRESQL_USER)\"; \
			create user \"$(GRAFANA_POSTGRESQL_USER)\" password '$(POSTGRESQL_PASSWORD)'; \
			grant usage on schema $(POSTGRESQL_SCHEMA) to \"$(GRAFANA_POSTGRESQL_USER)\"; \
			grant select on all tables in schema $(POSTGRESQL_SCHEMA) to \"$(GRAFANA_POSTGRESQL_USER)\"; \
			alter user \"$(GRAFANA_POSTGRESQL_USER)\" in database $(POSTGRESQL_DATABASE) set search_path to $(POSTGRESQL_SCHEMA);"
.PHONY: pguser

pgconnect:
	$(kubectl) run psql-$(COMPONENT_NAME) -ti --rm --image=postgres --restart=Never --env="PGPASSWORD=$$POSTGRESQL_PASSWORD" -- \
		psql -h $(POSTGRESQL_HOST) -p $(POSTGRESQL_PORT) -U $(GRAFANA_POSTGRESQL_USER) $(POSTGRESQL_DATABASE) -c '\d'
.PHONY: pgconnect

pgconnectadmin:
	$(kubectl) run psql-$(COMPONENT_NAME) -ti --rm --image=postgres --restart=Never --env="PGPASSWORD=$$POSTGRESQL_ADMIN_PASSWORD" -- \
		psql -h $(POSTGRESQL_HOST) -p $(POSTGRESQL_PORT) -U $(POSTGRESQL_ADMIN_USER) $(POSTGRESQL_DATABASE) -c '\d'
.PHONY: pgconnectadmin

oidc:
	$(kubectl) apply -f oidc.yaml
.PHONY: oidc

install:
	-$(kubectl) create ns $(NAMESPACE)
	if ! $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$'; then \
		echo Installing...; \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait \
			--values values.yaml \
			--values values-okta.yaml \
			$(INGRESS_TLS_VALUES) \
			$(POSTGRESQL_VALUES) \
			--version $(CHART_VERSION); \
	else \
		$(MAKE) upgrade; \
	fi

upgrade:
	@echo Upgrading...
	$(helm) upgrade $(COMPONENT_NAME) charts/$(notdir $(HELM_CHART)) \
		--namespace $(NAMESPACE) \
		--wait \
		--values values.yaml \
		--values values-okta.yaml \
		$(INGRESS_TLS_VALUES) \
		$(POSTGRESQL_VALUES) \
		--version $(CHART_VERSION)

output:
	@echo Outputs:
	@$(kubectl) get secret $(COMPONENT_NAME) -o json | \
		jq -r '"password = " + .data["admin-password"]' | \
		$(HUB) util otp
	@echo

undeploy: init
	-$(kubectl) delete -f oidc.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0

clean:
	rm -rf $(HELM_HOME) charts/$(notdir $(HELM_CHART))

-include ../Mk/phonies
