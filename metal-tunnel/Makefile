.DEFAULT_GOAL := deploy

export PROXY_SPACE ?= proxy
export CLOUD_KIND  ?= aws

deploy:
	$(MAKE) -C $(CLOUD_KIND) $@

undeploy:
	$(MAKE) -C $(CLOUD_KIND) $@

-include ../Mk/phonies
