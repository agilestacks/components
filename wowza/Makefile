.DEFAULT_GOAL := deploy

export HELM_HOME           ?= $(shell pwd)/.helm
export NAMESPACE    	   ?= wowza
export COMPONENT_NAME      ?= wowza
export DOMAIN_NAME         ?= default
export kubectl             ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
export helm                ?= helm --kube-context="$(DOMAIN_NAME)" --tiller-namespace="kube-system"


deploy:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f secret.yaml
	$(kubectl) create configmap configs --from-file=serverxml=conf/Server.xml \
				--from-file=log4j=conf/log4j.properties
	$(kubectl) apply -f deployment.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f ingress.yaml

.PHONY: deploy

undeploy:
	$(kubectl) delete -f ingress.yaml
	$(kubectl) delete -f deployment.yaml
	$(kubectl) delete configmap configs
	$(kubectl) delete -f service.yaml
	$(kubectl) delete -f secret.yaml

.PHONY: undeploy
