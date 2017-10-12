.DEFAULT_GOAL := deploy

export DOMAIN_NAME         ?= default

deploy:
	mkdir -p result
	cp -f kubeconfig result/kubeconfig.$(DOMAIN_NAME)
	$(MAKE) output

undeploy:
	rm -f result/kubeconfig.$(DOMAIN_NAME) || true

output:
	@echo Outputs:
	@echo kubeconfig = $(abspath .)/result/kubeconfig.$(DOMAIN_NAME)
.PHONY: output
