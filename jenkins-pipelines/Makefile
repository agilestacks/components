.DEFAULT_GOAL := deploy

export NAMESPACE ?= jenkins
export PIPELINES ?= asi-demo-nodejs,asi-demo-java
export NAMESPACE_PIPELINES ?= default

kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"
kubectl2 := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE_PIPELINES)"

deploy:
	- $(kubectl) create namespace $(NAMESPACE)
	- $(kubectl) create namespace $(NAMESPACE_PIPELINES)
	$(kubectl2) apply -f rbac.yaml
	$(eval , := ,)
	for pipeline in $(subst $(,), ,$(PIPELINES)) ; do \
		$(kubectl) apply -f $$pipeline.yaml ; \
	done
.PHONY: deploy

undeploy:
	$(kubectl2) delete -f rbac.yaml
	$(eval , := ,)
	for pipeline in $(subst $(,), ,$(PIPELINES)) ; do \
		$(kubectl) delete -f $$pipeline.yaml ; \
	done
.PHONY: undeploy
