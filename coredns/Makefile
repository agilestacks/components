.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= dns
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= dns
CHART_VERSION  ?= 1.10.0


kubectl := kubectl --context="$(DOMAIN_NAME)"

deploy: install

ifneq (,$(COREDNS_LISTEN_ADDR))
deploy: expose
endif

install:
	-$(kubectl) create ns $(NAMESPACE)
	$(kubectl) -n $(NAMESPACE) apply -f manifests.yaml

undeploy:
	$(kubectl) -n $(NAMESPACE) delete -f manifests.yaml

expose:
	$(kubectl) -n $(NAMESPACE) expose deployment $(COMPONENT_NAME) --name=etcd-metal --type=LoadBalancer --external-ip=$(ETCD_LISTEN_ADDR)

-include ../Mk/phonies
