.DEFAULT_GOAL := deploy

export TF_VAR_component          ?= external-dns
export TF_VAR_domain_name        ?=
export NAMESPACE                 ?= kube-system

export CLOUD_KIND          ?= $(error CLOUD_KIND must be defined)
ACM_CERTIFICATE_ARN ?=

deploy:
	make -C $(CLOUD_KIND) $@

undeploy:
	make -C $(CLOUD_KIND) $@
