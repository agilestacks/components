.DEFAULT_GOAL := deploy

kubectl ?= kubectl --context="$(DOMAIN_NAME)"

deploy:
		-$(kubectl) apply -f stackinfo-crd.yaml
		$(kubectl) apply -f stackinfo.yaml

undeploy:
		$(kubectl) delete stackinfo $(CONTAINER_NAME)
