.DEFAULT_GOAL := deploy

export DOMAIN_NAME ?= default

deploy: output
	mkdir -p result
	mv -f kubeconfig result/kubeconfig.$(DOMAIN_NAME)
.PHONY: output

undeploy:
	-rm -f result/kubeconfig.$(DOMAIN_NAME)
.PHONY: undeploy

output:
	@echo
	@echo Outputs:
	@echo kubeconfig = $(abspath .)/result/kubeconfig.$(DOMAIN_NAME)
	@echo
.PHONY: output
