.DEFAULT_GOAL := gen

export KF_TARBALL         := https://github.com/kubeflow/manifests/tarball/v1.0.2
# manifests-0.7-branch is a directory inside the tarball
export KF_TARBALL_FILE    := .cache/kubeflow.tar
export KF_REPO            := .cache/repo

# export HUB_ASI_LOCAL_REPO := $(abspath kfrepo)
export HUB_DEX_URL        := http://dex.kube-system.svc.cluster.local:5556/dex
LIBSONNET     := .cache/lib/kfctl.libsonnet
LIBSONNET     += .cache/lib/utils.libsonnet

kubectl       := kubectl --context="$(HUB_DOMAIN_NAME)" --namespace="$(HUB_COMPONENT_NAMESPACE)"

jq            := jq -cMr
curl          := curl -qfSL --silent --create-dirs
rsync         := rsync -aIuv --exclude-from '$(abspath .cpignore)'
jsonnet       := $(shell which jsonnet)
jsonnet       += $(addprefix -V ,$(filter HUB_%,$(.VARIABLES)))
jsonnet       += $(addprefix -V ,$(filter KF_%,$(.VARIABLES)))
jsonnet       += $(addprefix --jpath ,$(dir $(LIBSONNET)))
KF_DEF        := kfctl_istio_dex.json
KFCTL_TARBALL := https://github.com/kubeflow/kfctl/releases/download/v1.0.2/kfctl_v1.0.2-0-ga476281_$(shell uname -s | tr '[:upper:]' '[:lower:]').tar.gz
KF_APP        := kustomzie
kfctl         := $(shell which kfctl)
ifeq ($(kfctl),)
kfctl := $(abspath bin/kfctl)
export PATH := $(dir $(kfctl)):$(PATH)
endif


kubecontext: CURRENTT_CONTEXT := $(shell kubectl config get current-context)
kubecontext:
	@test "$(CURRENTT_CONTEXT)" == "$(HUB_DOMAIN_NAME)" \
	|| echo As kfctl relays on kubectl\'s current context so we are to switch it to $(HUB_DOMAIN_NAME) \
	&& kubectl config use-context "$(HUB_DOMAIN_NAME)"

$(kfctl):
	mkdir -p "$(@D)"
	$(curl) "$(KFCTL_TARBALL)" | tar xz -C "$(@D)"
	chmod +x "$@"

$(KF_TARBALL_FILE):
	mkdir -p $(dir $@)
	$(curl) "$(KF_TARBALL)" > "$@"

$(KF_REPO): $(KF_TARBALL_FILE)
	mkdir -p "$@"
	tar xf - -C "$@" --strip-components 1 < $(KF_TARBALL_FILE)

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

patch: $(KF_REPO)
	$(rsync) $(abspath ext)/ $^

dex bucket:
	$(MAKE) -C "$@"

namespace:
	$(kubectl) get namespace $(HUB_COMPONENT_NAMESPACE) 2>/dev/null || \
		$(kubectl) create namespace $(HUB_COMPONENT_NAMESPACE)

$(KF_DEF): $(KF_REPO)
$(KF_APP): $(KF_DEF)
$(KF_APP): build
apply delete build: $(kfctl) patch
apply delete: $(KF_APP)
apply: namespace bucket
apply build: $(KF_DEF)
	$(kfctl) $@ -V -f "$<"
apply delete: kubecontext

delete: $(KF_DEF) drop-finalizers
	$(kfctl) $@ --delete_storage -V -f "$<"

drop-finalizers:
	$(kubectl) get namespace $(HUB_COMPONENT_NAMESPACE) -o json \
		| jq '. | del(.spec.finalizers)' \
		| $(kubectl) replace --raw "/api/v1/namespaces/$(HUB_COMPONENT_NAMESPACE)/finalize" -f -

deploy: clean patch dex apply

undeploy: SA:=$(shell $(kubectl) get serviceaccount -l 'app.kubernetes.io/part-of=kubeflow' -o name | xargs)
undeploy: clean patch delete
	$(kubectl) delete --all --force applications
	# $(kubectl) delete --all --force profiles
	$(kubectl) delete --all --force validatingwebhookconfigurations
	$(kubectl) delete --all --force mutatingwebhookconfigurations
	$(kubectl) delete rolebinding,clusterrolebinding,sa centraldashboard
	$(kubectl) delete --all --force \
		daemonsets,replicasets,services,deployments,pods,rc,configmaps,secrets,services,ingress,statefulsets,gateways,envoyfilters,jobs.batch,jobs
	$(kubectl) delete $(SA)


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
	rm -rf $(KF_DEF) $(KF_REPO) .cache $(KF_APP) $(LIBSONNET) kustomize .cache/kube


.PHONY: deploy undeploy clean apply build delete wait wait_nons patch dex bucket
.PRECIOUS: %.libsonnet $(kfctl) $(KF_DEF)
.IGNORE: delete drop-finalizers cleanup-namespace oidc-delete dex bucket
.INTERMEDIATE: $(KF_TARBALL_FILE)

.DELETE_ON_ERROR: $(KF_DEF) $(KF_REPO)
