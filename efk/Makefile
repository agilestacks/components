.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= efk
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= logs
CLOUD_KIND     ?= aws

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f $(CLOUD_KIND)-storage-class.yaml
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

undeploy:
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

include ../Mk/phonies
