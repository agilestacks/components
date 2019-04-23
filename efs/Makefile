.DEFAULT_GOAL := deploy

BASE_DIR ?= default

ifeq ($(KUBE_FLAVOR),openshift)
	BASE_DIR=openshift
endif

deploy:
	$(MAKE) -C $(BASE_DIR) $@

undeploy:
	$(MAKE) -C $(BASE_DIR) $@

-include ../Mk/phonies
