.DEFAULT_GOAL := deploy

DOMAIN_NAME ?= $(error DOMAIN_NAME not deefined)
export KUBECONFIG  := $(abspath kubeconfig result/kubeconfig.$(DOMAIN_NAME))

$(KUBECONFIG):
	mkdir -p $(@D)
	cat kubeconfig > $@

deploy: output $(KUBECONFIG) $(CLOUD_KIND)/deploy

$(CLOUD_KIND)/$%:
	test ! -f $(CLOUD_KIND)/Makefile \
		|| $(MAKE) -C "$(@D)" $*

undeploy: $(CLOUD_KIND)/undeploy
	rm -f $(KUBECONFIG)

output:
	@echo
	@echo Outputs:
	@echo kubeconfig = $(KUBECONFIG)
	@echo

-include ../Mk/phonies
