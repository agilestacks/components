.DEFAULT_GOAL := gen

export KF_TARBALL         := https://github.com/kubeflow/manifests/archive/v0.7-branch.tar.gz
# manifests-0.7-branch is a directory inside the tarball
export KF_REPO            := $(abspath .cache/repo)
export KF_KUSTOM_REPO     := $(abspath kustomrepo)

# export HUB_ASI_LOCAL_REPO := $(abspath kfrepo)
export HUB_DEX_URL        := http://dex.kube-system.svc.cluster.local:5556/dex

kubectl      := kubectl -n "$(HUB_COMPONENT_NAMESPACE)"
jq           := jq -cMr
yq           := yq
curl         := curl -qfSL --silent --create-dirs
kfctl        := kfctl
untar        := tar xf
JSONNET_ARGS += $(addprefix -V ,$(filter HUB_%,$(.VARIABLES)))
JSONNET_ARGS += $(addprefix -V ,$(filter KF_%,$(.VARIABLES)))
jsonnet      := jsonnet $(JSONNET_ARGS)
KF_DEF       := kfctl-istio.yaml
LIBSONNET    := lib/kfctl.libsonnet

$(KF_REPO):
	mkdir -p $@
	$(curl) $(KF_TARBALL) | $(untar) - -C $@ --strip-components 1

%.libsonnet:
	$(curl) --output $@ https://github.com/agilestacks/jsonnet/raw/master/lib/$(@F)

%.json: $(LIBSONNET)
	test ! -f "$*.jsonnet" \
		|| $(jsonnet) $*.jsonnet > $@

%.yaml: $(LIBSONNET)
	test ! -f "$*.jsonnet" \
		|| $(jsonnet) $*.jsonnet | $(yq) r - > $@

apply build: $(KF_DEF) $(KF_REPO)
	$(kfctl) $@ -V -f "$<"

delete: $(KF_DEF) $(KF_REPO)
	- $(kfctl) $@ -V -f "$<"

undeploy: clean build delete wait_nons
deploy: clean build apply wait

EXPECTED_APPS := 28
WAIT_TIMEOUT  := 1800
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
	echo "ERROR timeout $(WAIT_TIMEOUT)sec; Moving on"; \

clean:
	rm -rf $(KF_DEF) $(KF_REPO) .cache kustomize $(LIBSONNET)

.PHONY: deploy undeploy clean apply build delete wait wait_nons
.PRECIOUS: %.libsonnet
