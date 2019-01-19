.DEFAULT_GOAL := deploy

NAMESPACE ?= argoproj
DOMAIN_NAME      ?= dev.stacks.delivery

export GOPATH := $(realpath .)/.go
export GOBIN  := $(GOPATH)/bin

IMAGE_PREFIX := agilestacks/argo-
REGISTRY_PASS ?= ~/.docker/agilestacks.txt

kubectl ?= kubectl --context="$(DOMAIN_NAME)" --namespace="$(TF_VAR_namespace)"

$(GOBIN):
	mkdir -p "$@"

$(GOPATH):
	mkdir -p "$@"

namespace:
	- $(kubectl) create namespace $(TF_VAR_namespace)
.PHONY: namespace

login:
	@ touch $(REGISTRY_PASS)
	@ echo "Please put Docker Hub password into $(REGISTRY_PASS)"
	cat $(REGISTRY_PASS) | docker login --username agilestacks --password-stdin
.PHONY: login

compile: $(GOPATH) $(GOBIN) 
	mkdir -p .$(GOPATH)/src/github.com/argoproj/
	git clone https://github.com/argoproj/argo-events.git $(GOPATH)/src/github.com/argoproj/argo-events
#	go get github.com/argoproj/argo-events
	go get -u github.com/golang/dep/cmd/dep
	cd $(GOPATH)/src/github.com/argoproj/argo-events && $(GOBIN)/dep ensure -vendor-only
	$(MAKE) -C $(GOPATH)/src/github.com/argoproj/argo-events clean all all-images IMAGE_PREFIX=$(IMAGE_PREFIX) DOCKER_PUSH=true
.PHONY: compile

deploy: namespace
	$(kubectl) apply -f argo-events-sa.yaml
	$(kubectl) apply -f argo-events-cluster-roles.yaml
	$(kubectl) apply -f gateway-crd.yaml
	$(kubectl) apply -f gateway-controller-configmap.yaml
	$(kubectl) apply -f gateway-controller-deployment.yaml
	$(kubectl) apply -f sensor-crd.yaml
	$(kubectl) apply -f sensor-controller-configmap.yaml
	$(kubectl) apply -f sensor-controller-deployment.yaml
.PHONY: deploy

undeploy:
	- $(kubectl) delete -f sensor-controller-deployment.yaml
	- $(kubectl) delete -f sensor-controller-configmap.yaml
	- $(kubectl) delete -f gateway-controller-deployment.yaml
	- $(kubectl) delete -f gateway-controller-configmap.yaml
	- $(kubectl) delete -f argo-events-cluster-roles.yaml
	- $(kubectl) delete -f argo-events-sa.yaml
.PHONY: undeploy

