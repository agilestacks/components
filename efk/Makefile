.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= logs
export COMPONENT_NAME      ?= efk
export DOMAIN_NAME         ?= default

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
helm    ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"

CLOUD_KIND ?= aws

deploy:
	-$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f $(CLOUD_KIND)-storage-class.yaml
	$(kubectl) create configmap es-config \
		--from-file=conf/elasticsearch.yml \
		--from-file=conf/jvm.options \
		--from-file=conf/log4j2.properties \
		--from-file=conf/post-start-hook.sh
	$(kubectl) create configmap cerebro-config --from-file=conf/cerebro.conf
	$(kubectl) apply -f es-env.yaml
	$(kubectl) apply -f es-statefulset.yaml
	$(kubectl) apply -f es-service.yaml
	$(kubectl) apply -f fluentd-es-configmap.yaml
	$(kubectl) apply -f fluentd-es-ds.yaml
	$(kubectl) apply -f es-cerebro.yaml
	$(kubectl) apply -f kibana-deployment.yaml
	$(kubectl) apply -f kibana-service.yaml
.PHONY: deploy

undeploy:
	-$(kubectl) delete configmap es-config
	-$(kubectl) delete configmap cerebro-config
	-$(kubectl) delete -f es-env.yaml
	-$(kubectl) delete -f es-statefulset.yaml
	-$(kubectl) delete -f es-service.yaml
	-$(kubectl) delete -f fluentd-es-configmap.yaml
	-$(kubectl) delete -f fluentd-es-ds.yaml
	-$(kubectl) delete -f kibana-deployment.yaml
	-$(kubectl) delete -f kibana-service.yaml
	-$(kubectl) delete -f es-cerebro.yaml
	-$(kubectl) delete pvc -l k8s-app=elasticsearch-logging
.PHONY: undeploy
