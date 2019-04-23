.DEFAULT_GOAL := deploy

export CLOUD_KIND  ?= aws
export STORAGE_KIND ?= local

deploy:
	$(MAKE) -C $(CLOUD_KIND) $@

undeploy:
	$(MAKE) -C $(CLOUD_KIND) $@

-include ../Mk/phonies
