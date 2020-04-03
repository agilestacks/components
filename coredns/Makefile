.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= dns
DOMAIN_NAME    ?= test.dev.superhub.io
NAMESPACE      ?= dns
CHART_VERSION  ?= 1.10.0


kubectl := kubectl --context="$(DOMAIN_NAME)"

deploy: install

ifneq (,$(COREDNS_EXPOSE_ADDR))
deploy: expose
endif

install:
	-$(kubectl) create ns $(NAMESPACE)
	$(kubectl) -n $(NAMESPACE) apply -f manifests.yaml

undeploy:
	$(kubectl) -n $(NAMESPACE) delete -f manifests.yaml

expose:
	-$(kubectl) -n $(NAMESPACE) delete service coredns-udp coredns-tcp
	$(kubectl) -n $(NAMESPACE) expose deployment $(COMPONENT_NAME) --name=coredns-tcp --type=LoadBalancer --external-ip=$(COREDNS_EXPOSE_ADDR) --target-port=53 --port=53 --protocol=TCP
	$(kubectl) -n $(NAMESPACE) expose deployment $(COMPONENT_NAME) --name=coredns-udp --type=LoadBalancer --external-ip=$(COREDNS_EXPOSE_ADDR) --target-port=53 --port=53 --protocol=UDP

-include ../Mk/phonies
