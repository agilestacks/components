.DEFAULT_GOAL := deploy

export CLOUD_KIND  ?= aws

deploy:
	$(MAKE) -C $(CLOUD_KIND) $@

undeploy:
	$(MAKE) -C $(CLOUD_KIND) $@

-include ../Mk/phonies
