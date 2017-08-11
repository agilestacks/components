.DEFAULT_GOAL := deploy

export DOMAIN_NAME        ?= default 
export NAMESPACE  ?= dex

export kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy-test:
	@echo $(kubectl)
	@echo Outputs:
	@echo login = admin@agilestacks.com
	@echo password = secret
	@echo Dex deployed
.PHONY: deploy-test

deploy:
	sh ./gencert.sh
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f ca-cert-secret.yaml
	$(kubectl) create secret tls dex-ingress-tls-secret -n $(NAMESPACE) --cert=ssl/cert.pem --key=ssl/key.pem
	$(kubectl) apply -f grpc-client-secret.yaml
	$(kubectl) apply -f grpc-server-secret.yaml
	$(kubectl) apply -f configmap.yaml
	$(kubectl) apply -f deployment.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f ingress.yaml
	
	$(MAKE) output
.PHONY: deploy

output:
	@echo Outputs:
	@echo login = admin@agilestacks.com
	@echo password = secret
.PHONY: output

undeploy:
	$(kubectl) delete -f ingress.yaml | true
	$(kubectl) delete -f service.yaml | true
	$(kubectl) delete -f deployment.yaml | true
	$(kubectl) delete -f grpc-client-secret.yaml | true
	$(kubectl) delete -f grpc-server-secret.yaml | true
	$(kubectl) delete secret tls dex-ingress-tls-secret -n $(NAMESPACE) | true
	$(kubectl) delete -f ca-cert-secret.yaml | true
	$(kubectl) delete -f configmap.yaml | true
	
	@rm -rf ssl
.PHONY: undeploy
