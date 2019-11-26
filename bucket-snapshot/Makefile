.DEFAULT_GOAL := deploy

COMPONENT_NAME ?= bucket-snapshot
DOMAIN_NAME    ?= test.dev.superhub.io

BACKUP_BUCKET ?= terraform.agilestacks.com
BACKUP_REGION ?= us-east-1

aws := aws

ifneq ($(BUCKET_KIND),s3)
$(error only S3 buckets are supported)
endif

ifeq ($(SNAPSHOT),)
deploy:
else
deploy: check restore
endif
undeploy:

check:
	$(eval flag := s3://$(BUCKET_NAME)/$(PREFIX).restored)
	@if $(aws) --region=$(BACKUP_REGION) s3 ls $(flag); then \
		echo "$(flag) exist; remove it to restore from snapshot"; \
		exit 1; \
	fi

restore:
	test -n "$(SNAPSHOT)"
	$(eval dir := $(shell mktemp -d))
	$(aws) --region=$(BACKUP_REGION) s3 cp $(SNAPSHOT) - | \
		tar xj -C $(dir) -f -
	$(aws) --region=$(BUCKET_REGION) s3 sync --delete $(dir)/$(PREFIX) s3://$(BUCKET_NAME)/$(PREFIX)
	echo | $(aws) --region=$(BUCKET_REGION) s3 cp - s3://$(BUCKET_NAME)/$(PREFIX).restored
	rm -rf $(dir)

backup:
	$(eval dir := $(shell mktemp -d))
	$(eval snapshot := s3://$(BACKUP_BUCKET)/$(DOMAIN_NAME)/backup/bucket-snapshot/$(COMPONENT_NAME)/$(shell date +"%Y-%m-%d-%H-%M-%S").tar.bz2)
	$(aws) --region=$(BUCKET_REGION) s3 sync s3://$(BUCKET_NAME)/$(PREFIX) $(dir)/$(PREFIX)
	tar cj -C $(dir) -f - . | \
		$(aws) --region=$(BACKUP_REGION) s3 cp - $(snapshot)
	rm -rf $(dir)
	@echo Outputs:
	@echo kind = bucket
	@echo component.bucket.snapshot = $(snapshot)
	@echo component.bucket.snapshot.region = $(BACKUP_REGION)
	@echo

-include ../Mk/phonies
