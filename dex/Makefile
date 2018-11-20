.DEFAULT_GOAL := deploy

DOMAIN_NAME ?= dev.kubernetes.delivery
NAMESPACE   ?= dex

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f grpc-client-secret.yaml
	$(kubectl) apply -f grpc-server-secret.yaml
	$(kubectl) apply -f dex-rbac.yaml
	$(kubectl) get configmap dex || $(kubectl) apply -f configmap.yaml
	$(kubectl) apply -f deployment.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f service-api.yaml
	$(kubectl) apply -f ingress.yaml

	$(kubectl) apply -f auth_v1alpha1_oidc.yaml
	$(kubectl) apply -f auth-operator.yaml

undeploy:
	-$(kubectl) delete -f auth_v1alpha1_oidc.yaml
	-$(kubectl) delete -f auth-operator.yaml
	-$(kubectl) delete -f ingress.yaml
	-$(kubectl) delete -f service.yaml
	-$(kubectl) delete -f service-api.yaml
	-$(kubectl) delete -f deployment.yaml
	-$(kubectl) delete -f dex-rbac.yaml
	-$(kubectl) delete -f grpc-client-secret.yaml
	-$(kubectl) delete -f grpc-server-secret.yaml
	-$(kubectl) delete -f configmap.yaml

include ../Mk/phonies
