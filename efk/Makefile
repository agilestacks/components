.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= logs
export COMPONENT_NAME      ?= efk
export DOMAIN_NAME         ?= default
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"


deploy:
	$(kubectl) apply -f namespace.yaml

	$(kubectl) create --namespace $(NAMESPACE) configmap es-config --from-file=elasticsearch.yml \
																   --from-file=jvm.options \
																   --from-file=log4j2.properties
	$(kubectl) create --namespace $(NAMESPACE) configmap kibana-config --from-file=kibana.yml
	$(kubectl) create --namespace $(NAMESPACE) configmap fluentd-config --from-file=fluent.conf
	$(kubectl) create --namespace $(NAMESPACE) configmap cerebro-config --from-file=cerebro.conf

	$(kubectl) apply --namespace $(NAMESPACE) -f es-cerebro.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f es-discovery-svc.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f es-env.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f es-kibana.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f es-kibana-svc.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f es-master.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f es-fluentd.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f es-svc.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f es-storage-class.yaml
	$(kubectl) apply --namespace $(NAMESPACE) -f es-ebs-volume-claim.yaml
.PHONY: deploy

undeploy:
	$(kubectl) delete --namespace $(NAMESPACE) configmap es-config
	$(kubectl) delete --namespace $(NAMESPACE) configmap kibana-config
	$(kubectl) delete --namespace $(NAMESPACE) configmap fluentd-config
	$(kubectl) delete --namespace $(NAMESPACE) configmap cerebro-config
	$(kubectl) delete --namespace $(NAMESPACE) -f es-cerebro.yaml
	$(kubectl) delete --namespace $(NAMESPACE) -f es-discovery-svc.yaml
	$(kubectl) delete --namespace $(NAMESPACE) -f es-env.yaml
	$(kubectl) delete --namespace $(NAMESPACE) -f es-kibana.yaml
	$(kubectl) delete --namespace $(NAMESPACE) -f es-kibana-svc.yaml
	$(kubectl) delete --namespace $(NAMESPACE) -f es-master.yaml
	$(kubectl) delete --namespace $(NAMESPACE) -f es-fluentd.yaml
	$(kubectl) delete --namespace $(NAMESPACE) -f es-svc.yaml
	$(kubectl) delete --namespace $(NAMESPACE) -f es-storage-class.yaml
	$(kubectl) delete --namespace $(NAMESPACE) -f es-ebs-volume-claim.yaml
.PHONY: undeploy
