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
	$(kubectl) get namespace $(HUB_COMPONENT_NAMESPACE) -o name 2>/dev/null || \
		$(kubectl) create namespace $(HUB_COMPONENT_NAMESPACE)

$(K8S_MANIFESTS):
	$(kubectl) get -f "$@" -o name 2>/dev/null || \
		$(kubectl) create -f "$@"

$(KF_DEF): $(KF_REPO)
$(KF_APP): $(KF_DEF) build
apply delete build: $(kfctl) patch
apply delete: $(KF_APP) change-kubecontext
apply: namespace $(K8S_MANIFESTS)

apply build: $(KF_DEF)
	$(kfctl) $@ -V -f "$<"

delete: $(KF_DEF)
	$(kubectl) delete -f k8s/certificate.yaml --wait
	$(kfctl)   delete --delete_storage -V -f "$(KF_DEF)"

change-kubecontext:
	kubectl config use-context "$(HUB_DOMAIN_NAME)"

delete-namespace/%:
	if $(kubectl) get namespace '$*' -o name 2>/dev/null; then \
		bin/delete-resources.sh -n '$*' --all --context='$(HUB_DOMAIN_NAME)'; \
		bin/delete-namespace.sh '$*' --context='$(HUB_DOMAIN_NAME)'; \
	fi

delete-profiles: ALL_PROFILES:=$(shell $(kubectl) get profile.kubeflow.org -o name 2>/dev/null)
delete-profiles: $(subst profile.kubeflow.org,delete-namespace,$(ALL_PROFILES=))
delete-profiles:
	$(kubectl) delete profile.kubeflow.org --all --wait 2>/dev/null

delete-webhooks:
	$(kubectl) delete  \
		mutatingwebhookconfiguration.admissionregistration.k8s.io/admission-webhook-mutating-webhook-configuration \
		mutatingwebhookconfiguration.admissionregistration.k8s.io/inferenceservice.serving.kubeflow.org \
		mutatingwebhookconfiguration.admissionregistration.k8s.io/katib-mutating-webhook-config \
		mutatingwebhookconfiguration.admissionregistration.k8s.io/seldon-mutating-webhook-configuration-kubeflow \
		mutatingwebhookconfiguration.admissionregistration.k8s.io/webhook.serving.knative.dev \
		validatingwebhookconfiguration.admissionregistration.k8s.io/config.webhook.serving.knative.dev  \
		validatingwebhookconfiguration.admissionregistration.k8s.io/inferenceservice.serving.kubeflow.org  \
		validatingwebhookconfiguration.admissionregistration.k8s.io/katib-validating-webhook-config  \
		validatingwebhookconfiguration.admissionregistration.k8s.io/seldon-validating-webhook-configuration-kubeflow  \
		validatingwebhookconfiguration.admissionregistration.k8s.io/validation.webhook.serving.knative.devc  2>/dev/null

deploy: clean apply

cleanup-istio:
	bin/delete-resources.sh \
		--context='$(HUB_DOMAIN_NAME)' \
		-n '$(HUB_ISTIO_NAMESPACE)' \
		-l 'app.kubernetes.io/part-of=kubeflow'

undeploy: clean delete-profiles delete delete-webhooks
undeploy: delete-namespace/$(HUB_KNATIVE_SERVING_NAMESPACE)
undeploy: delete-namespace/$(HUB_COMPONENT_NAMESPACE)
undeploy: cleanup-istio

clean:
	rm -rf $(KF_DEF) $(KF_REPO) .cache $(KF_APP) $(LIBSONNET) kustomize .cache/kube

.PHONY: deploy undeploy clean apply build delete patch bucket change-kubecontext
.PHONY: $(K8S_MANIFESTS) drop-namespace/$(HUB_KNATIVE_SERVING_NAMESPACE)
.PRECIOUS: %.libsonnet $(kfctl) $(KF_DEF)
.IGNORE: delete bucket undeploy delete-webhooks delete-profiles
.SILENT: undeploy
# comment intermediate to debug
.INTERMEDIATE: $(KF_TARBALL_FILE) $(KF_DEF)
