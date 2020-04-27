.DEFAULT_GOAL := deploy

DOMAIN_NAME ?= $(error DOMAIN_NAME not deefined)
export KUBECONFIG  := $(abspath kubeconfig result/kubeconfig.$(DOMAIN_NAME))

$(KUBECONFIG):
	mkdir -p $(@D)
	cat kubeconfig > $@

deploy: output $(KUBECONFIG)

ifneq ($(CLOUD_KIND),)
ifneq ($(wildcard $(CLOUD_KIND)/Makefile),)
$(CLOUD_KIND)/$%:
	test ! -f $(CLOUD_KIND)/Makefile \
		|| $(MAKE) -C "$(@D)" $*

deploy:   $(CLOUD_KIND)/deploy
undeploy: $(CLOUD_KIND)/undeploy
endif
endif

undeploy:
	rm -f $(KUBECONFIG)

output:
	@echo
	@echo Outputs:
	@echo kubeconfig = $(KUBECONFIG)
	@echo

-include ../Mk/phonies
