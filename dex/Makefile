.DEFAULT_GOAL := deploy

export DOMAIN_NAME ?= default
export NAMESPACE   ?= dex

export kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f grpc-client-secret.yaml
	$(kubectl) apply -f grpc-server-secret.yaml
	$(kubectl) apply -f dex-rbac.yaml
	$(kubectl) apply -f operator-rbac.yaml
	$(kubectl) get configmap dex || $(kubectl) apply -f configmap.yaml
	$(kubectl) apply -f deployment.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f service-api.yaml
	$(kubectl) apply -f ingress.yaml

	$(kubectl) apply -f dex-operator-configmap.yaml
	$(kubectl) apply -f dex-operator.yaml
.PHONY: deploy

undeploy:
	-$(kubectl) delete -f dex-operator.yaml
	-$(kubectl) delete -f dex-operator-configmap.yaml
	-$(kubectl) delete -f ingress.yaml
	-$(kubectl) delete -f service.yaml
	-$(kubectl) delete -f service-api.yaml
	-$(kubectl) delete -f deployment.yaml
	-$(kubectl) delete -f dex-rbac.yaml
	-$(kubectl) delete -f operator-rbac.yaml
	-$(kubectl) delete -f grpc-client-secret.yaml
	-$(kubectl) delete -f grpc-server-secret.yaml
	-$(kubectl) delete -f configmap.yaml
.PHONY: undeploy
