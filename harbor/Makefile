.DEFAULT_GOAL := deploy

export TF_VAR_domain             ?= dev.kubernetes.delivery
export TF_VAR_component          ?= harbor
export TF_VAR_namespace          ?= harbor
export TF_VAR_service_prefix     ?= svc
export TF_VAR_nginx_service_name ?= $(TF_VAR_component)-nginx-nginx-ingress-controller
export TF_VAR_pull_secret        ?= $(TF_VAR_component)-default-pullsecret

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(TF_VAR_domain)-$(TF_VAR_component)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log
export HELM_HOME   ?= $(shell pwd)/.helm
export CLOUD_KIND  ?= aws
export STORAGE_KIND ?= local

deploy:
	$(MAKE) -C $(CLOUD_KIND) $@ 

undeploy:
	$(MAKE) -C $(CLOUD_KIND) $@ 

-include ../Mk/phonies
