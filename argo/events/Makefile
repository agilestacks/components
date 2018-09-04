.DEFAULT_GOAL := deploy

TF_VAR_namespace ?= argo
DOMAIN_NAME      ?= dev.stacks.delivery

export GOPATH ?= $(realpath .)/.go
export GOBIN ?= $(GOPATH)/bin/$(shell uname -s | tr A-Z a-z)

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(TF_VAR_namespace)"

$(GOPATH):
	mkdir -p "$@"

namespace:
	- $(kubectl) create namespace $(TF_VAR_namespace)
.PHONY: namespace

compile: $(GOPATH)
	go get github.com/argoproj/argo-events
	go get -u github.com/golang/dep/cmd/dep
	cd $(GOPATH)/src/github.com/argoproj/argo-events && $(GOBIN)/dep ensure -vendor-only
	$(MAKE) -C $(GOPATH)/src/github.com/argoproj/argo-events clean all IMAGE_PREFIX=$(IMAGE_PREFIX) DOCKER_PUSH=true
.PHONY: compile

deploy:
	$(kubectl) apply -f argo-events-sa.yaml
	$(kubectl) apply -f argo-events-cluster-roles.yaml
	$(kubectl) apply -f sensor-crd.yaml
	$(kubectl) apply -f sensor-controller-configmap.yaml
	$(kubectl) apply -f sensor-controller-deployment.yaml
	$(kubectl) apply -f webhook.yaml
	$(kubectl) apply -f artifact.yaml
	$(kubectl) apply -f resource.yaml
	$(kubectl) apply -f calendar.yaml
	$(kubectl) apply -f stream.yaml
.PHONY: deploy

undeploy:
	- $(kubectl) delete -f calendar.yaml
	- $(kubectl) delete -f stream.yaml
	- $(kubectl) delete -f artifact.yaml
	- $(kubectl) delete -f webhook.yaml
	- $(kubectl) delete -f resource.yaml
	- $(kubectl) delete -f sensor-controller-deployment.yaml
	- $(kubectl) delete -f sensor-controller-configmap.yaml
	- $(kubectl) delete -f sensor-crd.yaml
	- $(kubectl) delete -f argo-events-cluster-roles.yaml
	- $(kubectl) delete -f argo-events-sa.yaml
.PHONY: undeploy

clean:
	rm -rf $(TF_DATA_DIR)
