.DEFAULT_GOAL := deploy


COMPONENT_NAME          ?= kubecost
DOMAIN_NAME             ?= test.dev.superhub.io
NAMESPACE               ?= kubecost
PROMETHEUS_NAMESPACE    ?= monitoring
SCRAPE_CONFIGS_NAME     ?= $(error SCRAPE_CONFIGS_NAME is not provided)
SCRAPE_CONFIGS_KEY      ?= $(error SCRAPE_CONFIGS_KEY is not provided)

kubectl            ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(PROMETHEUS_NAMESPACE)"
jq                 ?= jq
yq                 ?= yq


PROMETHEUS_ENTITY        := $(kubectl) get prometheus $(PROMETHEUS_NAME)-prometheus -o json
CURRENT_SCRAPE_NAME      := $(PROMETHEUS_ENTITY) | $(jq) -r .spec.additionalScrapeConfigs.name
CURRENT_SCRAPE_KEY       := $(PROMETHEUS_ENTITY) | $(jq) -r .spec.additionalScrapeConfigs.key

SCRAPES_CONCURENCY_QUERY := $(jq) '.spec.additionalScrapeConfigs? | select(.name and .key and (.name != "$(SCRAPE_CONFIGS_NAME)" or .key != "$(SCRAPE_CONFIGS_KEY)"))'
SCRAPES_CONCURENCY       := $(shell $(PROMETHEUS_ENTITY) | $(SCRAPES_CONCURENCY_QUERY))

ifeq ($(SCRAPES_CONCURENCY),)
    SCRAPES_FLOW := autonomy
else
    SCRAPES_FLOW := concurency
endif

TEMPDIR            := $(shell mkdir -p .artifacts; mktemp -d .artifacts/XXXXXX)
CURRENT_SECRET     := $(TEMPDIR)/current-secret.json
CURRENT_SCRAPES    := $(TEMPDIR)/current-scrapes.json
KUBECOST_SCRAPE    := $(TEMPDIR)/kubecost-scrape.json
SCRAPES_CONCURENCY := $(TEMPDIR)/scrapes-concurency.json

.PHONY: $(CURRENT_SECRET)

$(CURRENT_SECRET):
	$(kubectl) get secret `$(CURRENT_SCRAPE_NAME)` -o json > $@

$(CURRENT_SCRAPES): $(CURRENT_SECRET)
	cat $(CURRENT_SECRET) | $(jq) -r ".data.\"`$(CURRENT_SCRAPE_KEY)`\"" | base64 -d | yq read -j - > $@

$(KUBECOST_SCRAPE): scrape-config.yaml
	cat scrape-config.yaml | $(yq) read - 'stringData."$(SCRAPE_CONFIGS_KEY)"' | $(yq) read -j - "0" > $@

$(SCRAPES_CONCURENCY): $(CURRENT_SCRAPES) $(KUBECOST_SCRAPE)
	jsonnet concurency-scrape.jsonnet \
		--ext-str SECRET_KEY=`$(CURRENT_SCRAPE_KEY)` \
		--ext-code CURRENT_SCRAPES="`cat $(CURRENT_SCRAPES)`" \
		--ext-code KUBECOST_SCRAPE="`cat $(KUBECOST_SCRAPE)`" > $@

scrapes-concurency: $(SCRAPES_CONCURENCY)
	@echo Concurrency scrapes flow
	@echo Patching `$(CURRENT_SCRAPE_NAME)` secret
	$(kubectl) patch secret `$(CURRENT_SCRAPE_NAME)` --type=merge -p "`cat $(SCRAPES_CONCURENCY)`"

scrapes-autonomy:
	@echo Autonomy scrapes flow
	$(kubectl) apply -f scrape-config.yaml
	$(kubectl) patch prometheus $(PROMETHEUS_NAME)-prometheus --type=merge -p "`cat kubecost-prometheus.yaml`"

deploy: scrapes-${SCRAPES_FLOW}
	$(kubectl) apply -f rules.yaml

destroy:
	- $(kubectl) delete -f rules.yaml
	- $(kubectl) delete -f scrape-config.yaml

clean:
	rm -rf .artifacts

-include ../../Mk/phonies
