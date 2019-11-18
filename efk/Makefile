.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= efk
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= logs
CLOUD_KIND     ?= aws

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

ifeq ($(CURATOR_ENABLED),true)
deploy: install curator
undeploy: uninstall uncurator
else
deploy: install retain
undeploy: uninstall unretain
endif

install:
	$(kubectl) apply -f namespace.yaml
	-$(kubectl) delete configmap es-config
	$(kubectl) create configmap es-config \
		--from-file=conf/elasticsearch.yml \
		--from-file=conf/jvm.options \
		--from-file=conf/log4j2.properties \
		--from-file=conf/post-start-hook.sh
	-$(kubectl) delete configmap cerebro-config
	$(kubectl) create configmap cerebro-config --from-file=conf/cerebro.conf
	$(kubectl) apply -f es-env-cm.yaml
	$(kubectl) apply -f es-secrets.yaml
	$(kubectl) apply -f es-statefulset.yaml
	$(kubectl) apply -f es-service.yaml
	kubectl --context="$(DOMAIN_NAME)" --namespace="kube-system" apply -f es-secrets.yaml
	kubectl --context="$(DOMAIN_NAME)" --namespace="kube-system" apply -f fluentd-es-configmap.yaml
	kubectl --context="$(DOMAIN_NAME)" --namespace="kube-system" apply -f fluentd-es-ds.yaml
	$(kubectl) apply -f es-cerebro.yaml
	$(kubectl) apply -f kibana-deployment.yaml
	$(kubectl) apply -f kibana-service.yaml

uninstall:
	-$(kubectl) delete configmap es-config
	-$(kubectl) delete configmap cerebro-config
	-$(kubectl) delete -f es-env-cm.yaml
	-$(kubectl) delete -f es-secrets.yaml
	-$(kubectl) delete -f es-statefulset.yaml
	-$(kubectl) delete -f es-service.yaml
	-kubectl --context="$(DOMAIN_NAME)" --namespace="kube-system" delete -f es-secrets.yaml
	-kubectl --context="$(DOMAIN_NAME)" --namespace="kube-system" delete -f fluentd-es-configmap.yaml
	-kubectl --context="$(DOMAIN_NAME)" --namespace="kube-system" delete -f fluentd-es-ds.yaml
	-$(kubectl) delete -f kibana-deployment.yaml
	-$(kubectl) delete -f kibana-service.yaml
	-$(kubectl) delete -f es-cerebro.yaml
	-$(kubectl) delete pvc -l k8s-app=elasticsearch-logging

retain:
	-$(kubectl) delete configmap retain-config
	$(kubectl) create configmap retain-config \
		--from-file=conf/retain.sh
	$(kubectl) apply -f retain-cron.yaml

unretain:
	-$(kubectl) delete -f retain-cron.yaml
	-$(kubectl) delete configmap retain-config

curator:
	-$(kubectl) delete configmap curator-config
	$(kubectl) create configmap curator-config \
		--from-file=conf/curator-config.yml \
		--from-file=conf/curator-action.yml
	$(kubectl) apply -f curator-cron.yaml

uncurator:
	-$(kubectl) delete -f curator-cron.yaml
	-$(kubectl) delete configmap curator-config

.PHONY: curator uncurator

-include ../Mk/phonies
