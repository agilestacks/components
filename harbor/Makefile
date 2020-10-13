.DEFAULT_GOAL := deploy

export CLOUD_KIND   ?= aws
export STORAGE_KIND ?= local
export NAMESPACE    ?= harbor

deploy:
	scripts/patch_tls.sh $(NAMESPACE) &
	$(MAKE) -C $(CLOUD_KIND) $@

undeploy:
	$(MAKE) -C $(CLOUD_KIND) $@

-include ../Mk/phonies
