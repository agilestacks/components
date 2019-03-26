.DEFAULT_GOAL := deploy

NAMESPACE ?= harbor
kubectl   ?= kubectl --namespace="$(NAMESPACE)"


namespace: 
	- $(kubectl) create namespace $(NAMESPACE)

deploy: namespace
	$(kubectl) apply -f ingress.yaml
	$(kubectl) apply -f ingress-notary.yaml

undeploy: 
	$(kubectl) delete -f ingress-notary.yaml
	$(kubectl) delete -f ingress.yaml

output:
	@ echo harbor_fqdn = $(shell $(kubectl) get ingress -o 'jsonpath={.items[0].spec.rules[0].host}')
