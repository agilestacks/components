.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= etcd-metal
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= dns

kubectl ?= kubectl --context="$(DOMAIN_NAME)"

deploy: install

ifneq (,$(ETCD_LISTEN_ADDR))
deploy: expose
endif

install:
	-$(kubectl) create ns $(NAMESPACE)
	$(kubectl) -n $(NAMESPACE) apply -f manifests.yaml

expose:
	$(kubectl) -n $(NAMESPACE) expose deployment $(COMPONENT_NAME) --name=etcd-metal --type=LoadBalancer --external-ip=$(ETCD_LISTEN_ADDR)

undeploy:
	$(kubectl) -n $(NAMESPACE) delete -f manifests.yaml

-include ../Mk/phonies
