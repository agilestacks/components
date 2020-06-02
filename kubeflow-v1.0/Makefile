.DEFAULT_GOAL := gen

export KF_TARBALL         := https://github.com/kubeflow/manifests/tarball/v1.0.2
# manifests-0.7-branch is a directory inside the tarball
export KF_REPO            := $(abspath .cache/repo)
export KF_KUSTOM_REPO     := $(abspath kustomrepo)

# export HUB_ASI_LOCAL_REPO := $(abspath kfrepo)
export HUB_DEX_URL        := http://dex.kube-system.svc.cluster.local:5556/dex
LIBSONNET     := $(abspath .cache/lib/kfctl.libsonnet)
LIBSONNET     += $(abspath .cache/lib/utils.libsonnet)

kubectl       := kubectl -n "$(HUB_COMPONENT_NAMESPACE)"
jq            := jq -cMr
curl          := curl -qfSL --silent --create-dirs
rsync         := rsync -aIuv --exclude-from '$(abspath .cpignore)'
jsonnet       := $(shell which jsonnet)
jsonnet       += $(addprefix -V ,$(filter HUB_%,$(.VARIABLES)))
jsonnet       += $(addprefix -V ,$(filter KF_%,$(.VARIABLES)))
jsonnet       += $(addprefix --jpath ,$(dir $(LIBSONNET)))
KF_DEF        := kfctl_istio_dex.json
KFCTL_TARBALL := https://github.com/kubeflow/kfctl/releases/download/v1.0.2/kfctl_v1.0.2-0-ga476281_$(shell uname -s | tr '[:upper:]' '[:lower:]').tar.gz

kfctl         := $(shell which kfctl)
ifeq ($(kfctl),)
kfctl := $(abspath bin/kfctl)
export PATH := $(dir $(kfctl)):$(PATH)
endif

$(kfctl):
	mkdir -p $(@D)
	$(curl) "$(KFCTL_TARBALL)" | tar xz -C $(@D)
	chmod +x $@

$(KF_REPO):
	mkdir -p $@
	$(curl) $(KF_TARBALL) | tar xf - -C $@ --strip-components 1

%.libsonnet:
	@ mkdir -p $(@D)
	$(curl) --output $@ https://github.com/agilestacks/jsonnet/raw/master/lib/$(@F)

%.yaml: $(LIBSONNET)
	@ mkdir -p $(@D)
	test ! -f "$*.jsonnet" || $(jsonnet) $*.jsonnet | yq r -P - > $@
	@ if ! test -s "$@"; then \
		echo "jsonnet exited with error"; \
		rm -f "$@"; \
		exit 1; \
	fi

%.json: $(LIBSONNET)
	@ mkdir -p $(@D)
	test ! -f "$*.jsonnet" || $(jsonnet) $*.jsonnet -o $@
	@ if ! test -s "$@"; then \
		echo "jsonnet exited with error"; \
		rm -f "$@"; \
		exit 1; \
	fi

# patches/%: $(KF_REPO)
# 	$(rsync) $@ $^/$* 
# patch: OVERLAYS:=$(sort $(dir $(wildcard patches/**)))
patch: $(KF_REPO)
	$(rsync) $(abspath hack)/ $^

dex:
	$(MAKE) -C "$@"

namespace:
	$(kubectl) get namespace $(HUB_COMPONENT_NAMESPACE) 2>/dev/null || \
		$(kubectl) create namespace $(HUB_COMPONENT_NAMESPACE)

apply build delete: $(KF_REPO) $(kfctl)
apply build: $(KF_DEF) namespace
	$(kfctl) $@ -V -f "$(abspath $<)"

drop-finalizers:
	$(kubectl) get namespace $(HUB_COMPONENT_NAMESPACE) -o json \
		| jq '. | del(.spec.finalizers)' \
		| $(kubectl) replace --raw "/api/v1/namespaces/$(HUB_COMPONENT_NAMESPACE)/finalize" -f -

delete: $(KF_DEF) drop-finalizers
	$(kfctl) $@ --delete_storage -V -f "$(abspath $<)"

deploy: clean patch dex build apply
undeploy: clean build patch delete cleanup-namespace
# undeploy: build delete wait_nons

wait: EXPECTED_APPS := 28
wait: WAIT_TIMEOUT  := 1800
wait:
	$(eval count_apps := $(kubectl) get applications.app.k8s.io -l 'app.kubernetes.io/managed-by=kfctl' -o json)
	$(eval count_apps += | $(jq) '[ .items[]? | select(.status.conditions[]?.type="ready").metadata.name ] | length')
	$(eval timeout    := $(shell echo "`date +%s` + $(WAIT_TIMEOUT)" | bc ))
	$(eval current_time   := date +%s)
	@ echo 'Waiting for kubeflow applications to report "ready"'
	@ while [ `$(current_time)` -le "$(timeout)" ]; do \
		ready=`$(count_apps)`; \
		if [ "$$ready" -ge '$(EXPECTED_APPS)' ]; then \
			echo "Succeeded (ready: $$ready; expected: $(EXPECTED_APPS))"; \
			exit 0; \
		fi; \
		echo "Still waiting (ready: $$ready; expected: $(EXPECTED_APPS))..."; \
		sleep 8; \
	done; \
	echo "ERROR timeout $(WAIT_TIMEOUT)sec"; \
	exit 1;

wait_nons:
	$(eval timeout := $(shell echo "`date +%s` + $(WAIT_TIMEOUT)" | bc ))
	$(eval current_time := date +%s)
	@ echo 'Waiting for $(HUB_COMPONENT_NAMESPACE) namespace to be deleted'
	@ while [ `$(current_time)` -le "$(timeout)" ]; do \
		rv=`$(kubectl) get namespace $(HUB_COMPONENT_NAMESPACE) > /dev/null 2>&1; echo $$?`; \
		$(kubectl) get namespace $(HUB_COMPONENT_NAMESPACE) > /dev/null 2>&1 || { \
			echo "Done!"; \
			exit 0; \
		}; \
		echo "Still waiting..."; \
		sleep 8; \
	done; \
	echo "ERROR timeout $(WAIT_TIMEOUT)sec; Moving on";

clean:
	rm -rf $(KF_DEF) $(KF_REPO) .cache kustomize $(LIBSONNET)
	# rm -rf $(KF_DEF) kustomize $(LIBSONNET)

.PHONY: deploy undeploy clean apply build delete wait wait_nons patch dex
.PRECIOUS: %.libsonnet $(kfctl) $(KF_DEF)
.IGNORE: delete drop-finalizers cleanup-namespace oidc-delete
.DELETE_ON_ERROR: $(KF_DEF) $(KF_REPO)

# cleanup-namespace: CRB:=$(shell $(kubectl) get clusterrolebindings -o json | \
# 	$(jq) '.items[] | select(.subjects[]?.namespace=="kubeflow").metadata.name')
cleanup-namespace:
	$(kubectl) delete applications --all
	$(kubectl) delete profiles --all
	$(kubectl) delete validatingwebhookconfigurations --all
	$(kubectl) delete mutatingwebhookconfigurations --all
