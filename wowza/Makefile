.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= wowza
DOMAIN_NAME    ?= dev.kubernetes.delivery
NAMESPACE      ?= wowza

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f ebs-volume-claim.yaml
	$(kubectl) apply -f secret.yaml
	$(kubectl) create configmap configs --from-file=serverxml=conf/Server.xml \
				--from-file=log4j=conf/log4j.properties
	$(kubectl) apply -f deployment.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f ingress.yaml

undeploy:
	-$(kubectl) delete -f ingress.yaml
	-$(kubectl) delete -f deployment.yaml
	-$(kubectl) delete configmap configs
	-$(kubectl) delete -f service.yaml
	-$(kubectl) delete -f secret.yaml
	-$(kubectl) delete -f ebs-volume-claim.yaml
	-$(kubectl) delete -f storage-class.yaml

-include ../Mk/phonies
