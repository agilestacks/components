.DEFAULT_GOAL := deploy

export NAMESPACE ?= jenkins
export PIPELINES ?= asi-demo-nodejs,asi-demo-java

kubectl := kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(eval , := ,)
	for pipeline in $(subst $(,), ,$(PIPELINES)) ; do \
		$(kubectl) apply -f $$pipeline.yaml ; \
	done
.PHONY: deploy

undeploy:
	$(eval , := ,)
	for pipeline in $(subst $(,), ,$(PIPELINES)) ; do \
		$(kubectl) delete -f $$pipeline.yaml ; \
	done
.PHONY: undeploy
