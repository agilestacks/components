.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= prometheus
export COMPONENT_NAME      ?= prometheus
export DOMAIN_NAME         ?= default
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"
export generator		   ?= ./grafana-gen/bin/grafana_dashboards_generate.sh --namespace "$(NAMESPACE)"

deploy: clean init wait install_operator install_prom install_alertmanager install_kube_prom install_grafana output
.PHONY: deploy

init:
	@mkdir -p $(HELM_HOME)
	@mkdir -p grafana-gen/output
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

install_operator:
ifeq ($(findstring $(COMPONENT_NAME)-operator, $(shell $(helm) list -q | xargs)),)
	$(helm) install charts/prometheus-operator \
		--name $(COMPONENT_NAME)-operator \
		--namespace $(NAMESPACE) \
		--replace \
		--wait \
		--values values-operator.yaml
endif
.PHONY: install_operator

install_kube_prom:
ifeq ($(findstring $(COMPONENT_NAME)-kube-prom, $(shell $(helm) list -q | xargs)),)
	$(helm) install charts/kube-prometheus \
		--name $(COMPONENT_NAME)-kube-prom \
		--namespace $(NAMESPACE) \
		--replace \
		--wait \
		--values values-kube-prometheus.yaml
endif
.PHONY: install_kube_prom

install_alertmanager:
ifeq ($(findstring $(COMPONENT_NAME)-alertmanager, $(shell $(helm) list -q | xargs)),)
	$(helm) install charts/alertmanager \
		--name $(COMPONENT_NAME)-alertmanager \
		--namespace $(NAMESPACE) \
		--replace \
		--wait \
		--values values-alertmanager.yaml
endif
.PHONY: install_alertmanager

install_grafana:
ifeq ($(findstring $(COMPONENT_NAME)-grafana, $(shell $(helm) list -q | xargs)),)
	$(generator) -s 1000000 -o grafana-gen/output/dashboards-configmap.yaml \
				-i grafana-gen/templates/grafana-dashboards --apply-configmap --apply-type create
	$(helm) install charts/grafana \
		--name $(COMPONENT_NAME)-grafana \
		--namespace $(NAMESPACE) \
		--replace \
		--wait \
		--values values-grafana.yaml
endif
.PHONY: install_grafana

install_prom:
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),)
	$(helm) install charts/prometheus \
		--name $(COMPONENT_NAME) \
		--namespace $(NAMESPACE) \
		--replace \
		--wait \
		--values values-prometheus.yaml
endif
.PHONY: install_prom

undeploy: init
ifeq ($(findstring $(COMPONENT_NAME)-grafana, $(shell $(helm) list -q | xargs)),$(COMPONENT_NAME)-grafana)
	$(helm) delete --purge $(COMPONENT_NAME)-grafana
endif
ifeq ($(findstring $(COMPONENT_NAME)-kube-prom, $(shell $(helm) list -q | xargs)),$(COMPONENT_NAME)-kube-prom)
	$(helm) delete --purge $(COMPONENT_NAME)-kube-prom
endif
ifeq ($(findstring $(COMPONENT_NAME), $(shell $(helm) list -q | xargs)),$(COMPONENT_NAME))
	$(helm) delete --purge $(COMPONENT_NAME)
endif
ifeq ($(findstring $(COMPONENT_NAME)-alertmanager, $(shell $(helm) list -q | xargs)),$(COMPONENT_NAME)-alertmanager)
	$(helm) delete --purge $(COMPONENT_NAME)-alertmanager
endif
ifeq ($(findstring $(COMPONENT_NAME)-operator, $(shell $(helm) list -q | xargs)),$(COMPONENT_NAME)-operator)
	$(helm) delete --purge $(COMPONENT_NAME)-operator
endif

	$(kubectl) get --namespace $(NAMESPACE) cm/grafana-dashboards-0 -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) jobs/$(COMPONENT_NAME)-operator-$(COMPONENT_NAME)-operator-get-crd -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) jobs/$(COMPONENT_NAME)-operator-$(COMPONENT_NAME)-operator-create-sm-job -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) statefulsets/$(COMPONENT_NAME)-$(COMPONENT_NAME) -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) statefulsets/alertmanager-$(COMPONENT_NAME)-alertmanager -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) svc/$(COMPONENT_NAME)-operated -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) svc/alertmanager-operated -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) secrets/$(COMPONENT_NAME)-prometheus -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) ServiceMonitors/$(COMPONENT_NAME)-operator -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) crd/alertmanagers.monitoring.coreos.com -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) crd/prometheuses.monitoring.coreos.com -o=yaml|$(kubectl) delete -f - || true
	$(kubectl) get --namespace $(NAMESPACE) crd/servicemonitors.monitoring.coreos.com -o=yaml|$(kubectl) delete -f - || true
.PHONY: undeploy

clean:
	@rm -rf $(HELM_HOME)

output:
	@echo Outputs:
	@echo prometheus=http://$(COMPONENT_NAME)-prometheus.$(NAMESPACE).svc.cluster.local:9090
	@echo alertmanager=http://$(COMPONENT_NAME)-alertmanager-alertmanager.$(NAMESPACE).svc.cluster.local:9093
	@echo grafana=http://$(COMPONENT_NAME)-grafana-grafana.$(NAMESPACE).svc.cluster.local:80
	@echo
	@echo Prometheus has been installed successfully.
.PHONY: output

