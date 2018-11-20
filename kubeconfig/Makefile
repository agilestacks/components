.DEFAULT_GOAL := deploy

export DOMAIN_NAME ?= dev.kubernetes.delivery

deploy: output
	mkdir -p result
	mv -f kubeconfig result/kubeconfig.$(DOMAIN_NAME)

undeploy:
	-rm -f result/kubeconfig.$(DOMAIN_NAME)

output:
	@echo
	@echo Outputs:
	@echo kubeconfig = $(abspath .)/result/kubeconfig.$(DOMAIN_NAME)
	@echo

-include ../Mk/phonies
