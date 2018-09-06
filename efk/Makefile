.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= logs
export COMPONENT_NAME      ?= efk
export DOMAIN_NAME         ?= default
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"


deploy:
	-$(kubectl) apply -f namespace.yaml

	$(kubectl) create --namespace $(NAMESPACE) configmap es-config --from-file=conf/elasticsearch.yml \
																   --from-file=conf/jvm.options \
																   --from-file=conf/log4j2.properties \
																   --from-file=conf/post-start-hook.sh
	$(kubectl) create --namespace $(NAMESPACE) configmap cerebro-config --from-file=conf/cerebro.conf
	$(kubectl) apply -f $(CLOUD_KIND)-storage-class.yaml
	$(kubectl) apply -f es-env.yaml
	$(kubectl) apply -f es-statefulset.yaml
	$(kubectl) apply -f es-service.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f fluentd-es-configmap.yaml
	$(kubectl) apply -f fluentd-es-ds.yaml
	$(kubectl) apply -f es-cerebro.yaml
	$(kubectl) apply -f kibana-deployment.yaml
	$(kubectl) apply -f kibana-service.yaml
.PHONY: deploy

undeploy:
	-$(kubectl) delete --namespace $(NAMESPACE) configmap es-config
	-$(kubectl) delete --namespace $(NAMESPACE) configmap cerebro-config
	-$(kubectl) delete -f es-env.yaml
	-$(kubectl) delete -f es-statefulset.yaml
	-$(kubectl) delete -f es-service.yaml
	-$(kubectl) delete --namespace $(NAMESPACE) -f fluentd-es-configmap.yaml
	-$(kubectl) delete -f fluentd-es-ds.yaml
	-$(kubectl) delete -f kibana-deployment.yaml
	-$(kubectl) delete -f kibana-service.yaml
	-$(kubectl) delete -f es-cerebro.yaml
	-$(kubectl) delete --namespace $(NAMESPACE) pvc -l k8s-app=elasticsearch-logging
	-$(kubectl) delete -f es-storage-class.yaml
.PHONY: undeploy
