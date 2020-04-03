.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= etcd-metal
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= dns

kubectl ?= kubectl --context="$(DOMAIN_NAME)"

deploy: install

ifneq (,$(ETCD_EXPOSE_ADDR))
deploy: expose
ifeq (,$(ETCD_EXPOSE_PORT))
ETCD_EXPOSE_PORT := 12379
endif
endif

install:
	-$(kubectl) create ns $(NAMESPACE)
	$(kubectl) -n $(NAMESPACE) apply -f manifests.yaml

expose:
	-$(kubectl) -n $(NAMESPACE) delete service etcd-metal
	$(kubectl) -n $(NAMESPACE) expose deployment $(COMPONENT_NAME) --name=etcd-metal --type=LoadBalancer --external-ip=$(ETCD_EXPOSE_ADDR) --port $(ETCD_EXPOSE_PORT) --target-port 2379

undeploy:
	$(kubectl) -n $(NAMESPACE) delete -f manifests.yaml

-include ../Mk/phonies
