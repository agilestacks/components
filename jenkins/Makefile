.DEFAULT_GOAL := deploy

export DOMAIN_NAME        ?= default
export JENKINS_NAMESPACE  ?= jenkins
export VOLUME_TYPE        ?= hostpath

export kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(JENKINS_NAMESPACE)"

build:
	cd docker && $(MAKE) build
.PHONY: build

push:
	cd docker && $(MAKE) push
.PHONY: build

deploy-test:
	@echo $(kubectl)
	@echo Outputs:
	@echo password = secret
	@echo Jenkins deployed
.PHONY: deploy-test

deploy:
	$(kubectl) apply -f namespace.yaml
	$(kubectl) apply -f secrets.yaml
	$(kubectl) apply -f config.yaml
	$(kubectl) apply -f volume-$(VOLUME_TYPE).yaml
	$(kubectl) apply -f volume-claims.yaml
	$(kubectl) apply -f service.yaml
	$(kubectl) apply -f ingress.yaml
	$(kubectl) apply -f deployment.yaml

	$(MAKE) wait output
.PHONY: deploy

output:
	@echo Outputs:
	@echo password = secret
.PHONY: output

undeploy:
	$(kubectl) delete -f deployment.yaml | true
	$(kubectl) delete -f ingress.yaml | true
	$(kubectl) delete -f volume-claims.yaml | true
	$(kubectl) delete -f service.yaml | true
	$(kubectl) delete -f secrets.yaml | true
	$(kubectl) delete -f config.yaml | true
	$(kubectl) delete -f volume-$(VOLUME_TYPE).yaml | true
.PHONY: undeploy

wait:
	@for i in $$(seq 1 90); do \
		if [[ `$(kubectl) get pods -l 'project=jenkins,qualifier=master' --output=jsonpath='{.items..containerStatuses[?(@.ready==true)].containerID}'` ]]; then \
			exit 0; \
		fi; \
		echo "Waiting for Jenkins pod is up and running ($$i)..."; \
		sleep 10; \
	done; \
	echo "Timeout waiting for Jenkins"; \
	exit 1
