.DEFAULT_GOAL := gen

export KF_TARBALL         := https://github.com/kubeflow/manifests/archive/v1.1.0.tar.gz
# manifests-0.7-branch is a directory inside the tarball
export KF_TARBALL_FILE    := .cache/kubeflow.tar
export KF_REPO            := .cache/repo

# export HUB_ASI_LOCAL_REPO := $(abspath kfrepo)
export HUB_DEX_URL        := http://dex.kube-system.svc.cluster.local:5556/dex
LIBSONNET     := .cache/lib/kfctl.libsonnet
LIBSONNET     += .cache/lib/utils.libsonnet

kubectl       := kubectl --context="$(HUB_DOMAIN_NAME)"

jq            := jq -cMr
curl          := curl -qfSL --silent --create-dirs
rsync         := rsync -aIuv --exclude-from '$(abspath .cpignore)'
jsonnet       := $(shell which jsonnet)
jsonnet       += $(addprefix -V ,$(filter HUB_%,$(.VARIABLES)))
jsonnet       += $(addprefix -V ,$(filter KF_%,$(.VARIABLES)))
jsonnet       += $(addprefix --jpath ,$(dir $(LIBSONNET)))
KF_DEF        := kfctl_istio_dex.yaml
ARCH          := $(shell uname -s | tr '[:upper:]' '[:lower:]')
KFCTL_TARBALL := https://github.com/kubeflow/kfctl/releases/download/v1.1.0/kfctl_v1.1.0-0-g9a3621e_$(ARCH).tar.gz

KF_APP        := kustomzie
kfctl         := $(shell which kfctl)
ifeq ($(kfctl),)
kfctl := $(abspath bin/kfctl)
export PATH := $(dir $(kfctl)):$(PATH)
endif

K8S_MANIFESTS := $(wildcard k8s/*.yaml)

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

bucket:
	$(MAKE) -C "$@"

namespace:
	$(kubectl) get namespace $(HUB_COMPONENT_NAMESPACE) 2>/dev/null || \
		$(kubectl) create namespace $(HUB_COMPONENT_NAMESPACE)

$(K8S_MANIFESTS):
	$(kubectl) get -f "$@" 2>/dev/null || \
		$(kubectl) apply -f "$@"

$(KF_DEF): $(KF_REPO)
$(KF_APP): $(KF_DEF) build
apply delete build: $(kfctl) patch
apply delete: $(KF_APP) change-kubecontext
apply: namespace $(K8S_MANIFESTS)

apply build: $(KF_DEF)
	$(kfctl) $@ -V -f "$<"

delete: $(KF_DEF)
	$(kubectl) delete profile.kubeflow.org --all --wait
	$(kubectl) delete -f k8s/certificate.yaml --wait
	$(kfctl)   delete --delete_storage -V -f "$(KF_DEF)"

change-kubecontext:
	kubectl config use-context "$(HUB_DOMAIN_NAME)"

deploy: clean apply
drop-namespace/%:
	@ if $(kubectl) get namespace '$*' > /dev/null 2>&1; then \
		$(CURDIR)/bin/delete-resources.sh '$*' --all; \
		$(kubectl) get namespace '$*' -o json \
			| jq '. | del(.spec.finalizers)' \
			| $(kubectl) replace --raw '/api/v1/namespaces/$*/finalize' -f - ; \
		$(kubectl) delete namespace '$*'; \
	fi

ifneq ($(HUB_KNATIVE_SERVING_NAMESPACE),)
undeploy: drop-namespace/$(HUB_KNATIVE_SERVING_NAMESPACE)
endif
undeploy: ALL_PROFILES:=$(shell $(kubectl) get profile.kubeflow.org -o name 2>/dev/null)
undeploy: $(KF_DEF) $(subst profile.kubeflow.org,drop-namespace,$(ALL_PROFILES=))
undeploy: clean delete 
undeploy: 
	$(error ++ $(HUB_KNATIVE_SERVING_NAMESPACE))
	bin/delete-resources.sh '$(HUB_ISTIO_NAMESPACE)' -l app.kubernetes.io/part-of=kubeflow

clean:
	rm -rf $(KF_DEF) $(KF_REPO) .cache $(KF_APP) $(LIBSONNET) kustomize .cache/kube

.PHONY: deploy undeploy clean apply build delete patch bucket change-kubecontext
.PHONY: $(K8S_MANIFESTS) drop-namespace/$(HUB_KNATIVE_SERVING_NAMESPACE)
.PRECIOUS: %.libsonnet $(kfctl) $(KF_DEF)
.IGNORE: delete bucket undeploy
.SILENT: undeploy
# comment intermediate to debug
.INTERMEDIATE: $(KF_TARBALL_FILE) $(KF_DEF)
