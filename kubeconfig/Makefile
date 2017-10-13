.DEFAULT_GOAL := deploy

export DOMAIN_NAME ?= default

deploy:
	mkdir -p result
	mv -f kubeconfig result/kubeconfig.$(DOMAIN_NAME)
	$(MAKE) output

undeploy:
	-rm -f result/kubeconfig.$(DOMAIN_NAME)

output:
	@echo
	@echo Outputs:
	@echo kubeconfig = $(abspath .)/result/kubeconfig.$(DOMAIN_NAME)
	@echo
.PHONY: output
