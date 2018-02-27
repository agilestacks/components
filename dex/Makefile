.DEFAULT_GOAL := deploy

export TF_VAR_name ?= test
export DOMAIN_NAME ?= default
export NAMESPACE   ?= dex

export kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy-test:
	@echo $(kubectl)
	@echo Outputs:
	@echo login = admin@agilestacks.com
	@echo password = secret
	@echo Dex deployed
.PHONY: deploy-test

deploy: deploy-kube output
.PHONY: deploy

deploy-kube:
	sh ./gencert.sh
	$(kubectl) apply -f namespace.yaml
	$(kubectl) create secret tls dex-ingress-tls-secret -n $(NAMESPACE) --cert=ssl/cert.pem --key=ssl/key.pem | true
	$(kubectl) apply -f grpc-client-secret.yaml
	$(kubectl) apply -f grpc-server-secret.yaml
	$(kubectl) apply -f dex-rbac.yaml
	$(kubectl) apply -f operator-rbac.yaml
	$(kubectl) apply -f configmap.yaml
	$(kubectl) apply -f deployment.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f service-api.yaml
	$(kubectl) apply -f ingress.yaml

	$(kubectl) create secret tls oauth-ingress-tls-secret -n $(NAMESPACE) --cert=ssl/cert.pem --key=ssl/key.pem | true
	$(kubectl) apply -f dex-operator-configmap.yaml
	$(kubectl) apply -f dex-operator.yaml
.PHONY: deploy-kube

output:
	@echo Outputs:
	@echo login = admin@agilestacks.com
	@echo password = secret
.PHONY: output

undeploy:
	$(kubectl) delete -f dex-operator.yaml | true
	$(kubectl) delete -f dex-operator-configmap.yaml | true
	$(kubectl) delete -f ingress.yaml | true
	$(kubectl) delete -f service.yaml | true
	$(kubectl) delete -f service-api.yaml | true
	$(kubectl) delete -f deployment.yaml | true
	$(kubectl) delete -f dex-rbac.yaml | true
	$(kubectl) delete -f operator-rbac.yaml | true
	$(kubectl) delete -f grpc-client-secret.yaml | true
	$(kubectl) delete -f grpc-server-secret.yaml | true
	$(kubectl) delete secret tls dex-ingress-tls-secret -n $(NAMESPACE) | true
	$(kubectl) delete -f configmap.yaml | true

	$(kubectl) delete secret tls oauth-ingress-tls-secret -n $(NAMESPACE) | true

	@rm -rf ssl
	@rm -rf okta
.PHONY: undeploy
