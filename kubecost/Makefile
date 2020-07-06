.DEFAULT_GOAL := deploy


COMPONENT_NAME          ?= kubecost
DOMAIN_NAME             ?= test.dev.superhub.io
NAMESPACE               ?= kubecost
PROMETHEUS_NAMESPACE    ?= monitoring
HELM_REPO_URL           ?= https://kubecost.github.io/cost-analyzer/
HELM_REPO_NAME          ?= kubecost
HELM_CHART              ?= $(HELM_REPO_NAME)/cost-analyzer
VERSION                 ?= v1.59.0
AWS_DEFAULT_REGION      ?= us-east-2
HELM_HOME               ?= $(shell pwd)/.helm
TIMEOUT                 ?= 600
SCRAPE_CONFIGS_NAME     ?= $(error SCRAPE_CONFIGS_NAME is not provided)
SCRAPE_CONFIGS_KEY      ?= $(error SCRAPE_CONFIGS_KEY is not provided)

aws                ?= aws
kubectl            ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
kubectl-prometheus ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(PROMETHEUS_NAMESPACE)"
helm               ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
jq                 ?= jq
yq                 ?= yq


SPOT_DATA_ENABLED := $(if $(and $(SPOT_DATA_BUCKET_NAME), $(SPOT_DATA_BUCKET_REGION), $(SPOT_DATA_PREFIX)),true)

ifeq ($(SPOT_DATA_ENABLED),true)
    RESOLVE_AWS_ACCOUNT     := $(aws) sts get-caller-identity --query Account --output text
    HELM_ARGS_PROJECT_ID    := --set-string kubecostProductConfigs.projectID="`$(RESOLVE_AWS_ACCOUNT)`"
    HELM_ARGS_SPOT_DATA     := --values spot-data-feed.yaml
else
    SPOT_DATA_ENABLED:=
    HELM_ARGS_PROJECT_ID:=
    HELM_ARGS_SPOT_DATA:=
endif

PROMETHEUS_ENTITY        := $(kubectl-prometheus) get prometheus $(PROMETHEUS_NAME)-prometheus -o json
SCRAPES_CONCURENCY_QUERY := $(jq) '.spec.additionalScrapeConfigs? | select(.name and .key and (.name != "$(SCRAPE_CONFIGS_NAME)" or .key != "$(SCRAPE_CONFIGS_KEY)"))'
SCRAPES_CONCURENCY       := $(shell $(PROMETHEUS_ENTITY) | $(SCRAPES_CONCURENCY_QUERY))
CURRENT_SCRAPE_NAME      := $(PROMETHEUS_ENTITY) | $(jq) -r .spec.additionalScrapeConfigs.name
CURRENT_SCRAPE_KEY       := $(PROMETHEUS_ENTITY) | $(jq) -r .spec.additionalScrapeConfigs.key

ifeq ($(SCRAPES_CONCURENCY),)
    SCRAPES_FLOW := autonomy
else
    SCRAPES_FLOW := concurency
endif

# deploy: init fetch purge prometheus install wait
deploy: prometheus

init: $(HELM_HOME) charts
	$(helm) init --client-only --upgrade

$(HELM_HOME) charts:
	@rm -rf $@ && mkdir -p $@

fetch:
	$(helm) repo add kubecost $(HELM_REPO_URL)
	$(helm) fetch \
		--destination charts \
		--untar $(HELM_CHART) \
		--version $(VERSION)

purge:
	$(helm) list --deleted --failed -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' \
		&& $(helm) delete --purge $(COMPONENT_NAME) \
		|| exit 0

prometheus-scrapes-autonomy:
	@echo Autonomy scrapes flow
	$(kubectl-prometheus) apply -f prometheus/scrape-config.yaml
	$(kubectl-prometheus) patch prometheus $(PROMETHEUS_NAME)-prometheus --type=merge -p "`cat prometheus/kubecost-prometheus.yaml`"

prometheus-current-secret.json:
	$(kubectl-prometheus) get secret `$(CURRENT_SCRAPE_NAME)` -o json > $@

prometheus-current-scrapes.json: prometheus-current-secret.json
	cat prometheus-current-secret.json | $(jq) -r ".data.\"`$(CURRENT_SCRAPE_KEY)`\"" | base64 -d | yq read -j - > $@

prometheus-kubecost-scrape.json: prometheus/scrape-config.yaml
	cat prometheus/scrape-config.yaml | $(yq) read - 'stringData."$(SCRAPE_CONFIGS_KEY)"' | $(yq) read -j - "0" > $@

prometheus-scrapes-concurency.json: prometheus-current-scrapes.json prometheus-kubecost-scrape.json
	jsonnet prometheus/concurency-scrape.jsonnet \
		--ext-str SECRET_KEY=`$(CURRENT_SCRAPE_KEY)` \
		--ext-code CURRENT_SECRET="`cat prometheus-current-secret.json`" \
		--ext-code CURRENT_SCRAPES="`cat prometheus-current-scrapes.json`" \
		--ext-code KUBECOST_SCRAPE="`cat prometheus-kubecost-scrape.json`" > $@

prometheus-scrapes-concurency: prometheus-scrapes-concurency.json
	@echo Concurency scrapes flow
	$(kubectl-prometheus) patch secret `$(CURRENT_SCRAPE_NAME)` --type=merge -p "`cat prometheus-scrapes-concurency.json`"

prometheus: prometheus-scrapes-${SCRAPES_FLOW}
	$(kubectl-prometheus) apply -f prometheus/rules.yaml

install:
	$(kubectl) apply -f namespace.yaml

	if ! $(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$'; then \
		$(helm) install charts/$(notdir $(HELM_CHART)) \
			--name $(COMPONENT_NAME) \
			--namespace $(NAMESPACE) \
			--wait \
			--values values.yaml \
			$(HELM_ARGS_SPOT_DATA) \
			$(HELM_ARGS_PROJECT_ID) \
			--values prometheus.yaml \
			--version $(VERSION); \
	else \
		$(MAKE) upgrade; \
	fi

	$(kubectl) apply -f ingress.yaml

upgrade:
	$(helm) upgrade $(COMPONENT_NAME) charts/$(notdir $(HELM_CHART)) \
		--namespace $(NAMESPACE) \
		--wait \
		--values values.yaml \
		$(HELM_ARGS_SPOT_DATA) \
		$(HELM_ARGS_PROJECT_ID) \
		--values prometheus.yaml \
		--version $(VERSION)

wait:
	$(eval timeout=$(shell echo "`date +%s` + $(TIMEOUT)" | bc ))
	$(eval cost_analyzer_pod=$(kubectl) get pod -l app=cost-analyzer -o=json)
	$(eval check_conttainers=$(jq) '.items[]?.status.conditions[] | select(.type == "ContainersReady" and .status == "True")')
	@ echo "Waiting for Cost Analizer pod up and running"

	@ while [ `date +%s` -le "$(timeout)" ]; do \
		if [[ "`$(cost_analyzer_pod) | $(check_conttainers)`" ]]; then \
			echo " done"; \
			exit 0; \
		fi; \
		echo "still waiting..."; \
		sleep 8; \
	done; \
	echo " ERROR timeout $(TIMEOUT)sec"; \
	exit 1

undeploy: init destroy

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy:
	- $(kubectl) delete -f ingress.yaml
	$(helm) list -q --namespace $(NAMESPACE) | grep -E '^$(COMPONENT_NAME)$$' && \
		$(helm) delete --purge $(COMPONENT_NAME) || exit 0
	- $(kubectl-prometheus) delete -f prometheus/rules.yaml
	- $(kubectl-prometheus) delete -f prometheus/scrape-config.yaml

-include ../Mk/phonies
