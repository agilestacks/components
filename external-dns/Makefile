.DEFAULT_GOAL := deploy

export TF_VAR_component          ?= external-dns
export TF_VAR_domain_name        ?=
export NAMESPACE                 ?= kube-system

export SERVICE_PROVIDER          += rfc2136
ACM_CERTIFICATE_ARN ?=

deploy:
	make -C $(SERVICE_PROVIDER) $@

undeploy:
	make -C $(SERVICE_PROVIDER) $@
