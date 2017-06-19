.DEFAULT_GOAL := deploy

export kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(NAMESPACE)"

deploy-test:
	@echo $(kubectl)
	@echo Outputs:
	@echo password = supersecret
	@echo PostgreSQL deployed
.PHONY: deploy-test

deploy:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f config.yaml
	$(kubectl) apply -f secrets.yaml
	$(kubectl) apply -f volume-hostpath.yaml
	$(kubectl) apply -f volume-claim.yaml
	$(kubectl) apply -f pgsql-service.yaml
	$(kubectl) apply -f pgsql-deployment.yaml
	$(kubectl) apply -f pgweb-service.yaml
	$(kubectl) apply -f pgweb-deployment.yaml
	@echo Outputs:
	@echo password = supersecret
.PHONY: deploy

undeploy:
	$(kubectl) delete -f pgweb-deployment.yaml
	$(kubectl) delete -f pgweb-service.yaml
	$(kubectl) delete -f pgsql-deployment.yaml
	$(kubectl) delete -f pgsql-service.yaml
	$(kubectl) delete -f volume-claim.yaml
	$(kubectl) delete -f volume-hostpath.yaml
	$(kubectl) delete -f secrets.yaml
	$(kubectl) delete -f config.yaml
.PHONY: undeploy
