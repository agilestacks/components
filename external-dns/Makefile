.DEFAULT_GOAL := deploy

CLOUD_KIND ?= rfc2136

$(CLOUD_KIND):
	$(warning WARNING: Cloud unsupported provider: $@... skipping)

deploy: $(CLOUD_KIND)
	test ! -d "$<" || make -C "$<" $@

undeploy: $(CLOUD_KIND)
	test ! -d "$<" || make -C "$<" $@
