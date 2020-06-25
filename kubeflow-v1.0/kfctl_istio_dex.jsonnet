local kf                = import "kfctl.libsonnet";
local utils             = import "utils.libsonnet";

local istioNamespace    = kf.NameValue("namespace", "istio-system");
local ksystemNamespace  = kf.NameValue("namespace", "kube-system");
local certMgrNamespace  = kf.NameValue("namespace", "cert-manager");
local knativeNamespace  = kf.NameValue("namespace", "knative-serving");
local kubeflowNamespace = kf.NameValue("namespace", std.extVar("HUB_COMPONENT_NAMESPACE"));

// local name              = std.extVar("HUB_COMPONENT_NAME");
// local dexUrl = std.format("http://dex.%s.svc.cluster.local:5556/dex", kubeflowNamespace.value);
// local dexUrl      = std.extVar("HUB_OIDC_AUTH_URI");

local istio = [
  // kf.KustomizeConfig("istio/istio-crds", parameters=[istioNamespace]),
  // kf.KustomizeConfig("istio/istio-install", parameters=[istioNamespace]),
  kf.KustomizeConfig("istio/cluster-local-gateway", parameters=[istioNamespace]),
  kf.KustomizeConfig("istio/kfserving-gateway", parameters=[istioNamespace]),
  kf.KustomizeConfig("istio/istio", overlays=["agilestacks"],
    parameters=[kf.NameValue("clusterRbacConfig", "OFF")],
  ),
  kf.KustomizeConfig("istio/oidc-authservice", overlays=["application", "agilestacks"],
    parameters=[
      kf.NameValue("client_id",          std.extVar("HUB_OIDC_CLIENT_ID")),
      kf.NameValue("oidc_provider",      std.extVar("HUB_OIDC_AUTH_URI")),
      kf.NameValue("oidc_redirect_uri",  std.extVar("HUB_OIDC_REDIRECT_URI")),
      kf.NameValue("oidc_auth_url",      std.extVar("HUB_OIDC_AUTH_URI") + "/auth"),
      kf.NameValue("application_secret", std.extVar("HUB_OIDC_SECRET")),
      kf.NameValue("skip_auth_uri",      std.extVar("HUB_OIDC_AUTH_URI")),
      kf.NameValue("userid-header",      "kubeflow-userid"),
      // kf.NameValue("userid-prefix", ""),
      istioNamespace
      ]),
  kf.KustomizeConfig("istio/add-anonymous-user-filter", overlays=["agilestacks"]),
];

local installCertManager = false;
local certManager = if installCertManager then [
  kf.KustomizeConfig("cert-manager/cert-manager-crds", parameters=[certMgrNamespace],),
  kf.KustomizeConfig("cert-manager/cert-manager-kube-system-resources", parameters=[ksystemNamespace],),
  kf.KustomizeConfig("cert-manager/cert-manager", overlays=["self-signed", "application"], parameters=[certMgrNamespace],),
] else [];

local metacontroller = [
  kf.KustomizeConfig("application/application-crds"),
  kf.KustomizeConfig("application/application", overlays=["application"],),
  kf.KustomizeConfig("metacontroller"),
];

local argo = [
  kf.KustomizeConfig("argo", overlays = ["istio", "application", "agilestacks"])
];

local centraldashboard = [
  kf.KustomizeConfig("common/centraldashboard", 
    overlays=["istio", "application"],
    parameters=[kf.NameValue("userid-header", "kubeflow-userid")]),
];

local metadata = [
  kf.KustomizeConfig("metadata", overlays=["istio", "db", "application"]),
];

local spark = [
  kf.KustomizeConfig("spark/spark-operator", overlays=["application"]),
];

local pytorch = [
  kf.KustomizeConfig("pytorch-job/pytorch-job-crds", overlays=["application"]),
  kf.KustomizeConfig("pytorch-job/pytorch-operator", overlays=["application"]),
];

local kfserving = [
  kf.KustomizeConfig("knative/knative-serving-crds", overlays=["application"], parameters=[knativeNamespace]),
  kf.KustomizeConfig("knative/knative-serving-install", overlays=["application","agilestacks"], parameters=[knativeNamespace]),
  kf.KustomizeConfig("kfserving/kfserving-crds", overlays=["application"]),
  kf.KustomizeConfig("kfserving/kfserving-install", overlays=["application"]),
];

// local spartakus = [
//   kf.KustomizeConfig("common/spartakus", overlays=["application"],
//     parameters=[
//       kf.NameValue("usageId", std.md5(name)),
//       kf.NameValue("reportUsage", "false")
//     ],),
// ];

local jupyter = [
  kf.KustomizeConfig("jupyter/jupyter-web-app", 
    overlays=["istio", "application"],
    parameters=[kf.NameValue("userid-header", "kubeflow-userid")]),  
  kf.KustomizeConfig("jupyter/notebook-controller", overlays=["istio", "application"]),
];

local tensorboard = [
  kf.KustomizeConfig("tensorboard", overlays=["istio"]),
  kf.KustomizeConfig("tf-training/tf-job-crds", overlays=["application"]),
  kf.KustomizeConfig("tf-training/tf-job-operator", overlays=["application"]),
];

local katib = [
  kf.KustomizeConfig("katib/katib-crds", overlays=["application"]),
  kf.KustomizeConfig("katib/katib-controller", overlays=["istio", "application"]),
];

local pipeline = [
  kf.KustomizeConfig("pipeline/api-service", overlays=["application"]),
  kf.KustomizeConfig("pipeline/minio", overlays=["application"],
    parameters=[
      kf.NameValue("minioPvcName", "kf-"+std.extVar("HUB_COMPONENT")+"-minio")
    ]),
  kf.KustomizeConfig( "pipeline/mysql", overlays=["application"],
    parameters=[
      kf.NameValue("mysqlPvcName", "kf-"+std.extVar("HUB_COMPONENT")+"-minio")
    ]),
  kf.KustomizeConfig("pipeline/pipelines-runner", overlays=["application"]),
  kf.KustomizeConfig("pipeline/pipelines-ui", overlays=["istio", "application"]),
  kf.KustomizeConfig("pipeline/scheduledworkflow", overlays=["application"]),
  kf.KustomizeConfig("pipeline/pipeline-visualization-service", overlays=["application"]),
];

local seldon = [
  kf.KustomizeConfig("seldon/seldon-core-operator", overlays=["application"]),
];

local admissionWebHook = if installCertManager then [
  kf.KustomizeConfig("admission-webhook/webhook", overlays=["cert-manager", "application"]),
] else [
  kf.KustomizeConfig("admission-webhook/bootstrap", overlays=["application"]),
  kf.KustomizeConfig("admission-webhook/webhook", overlays=["application"]),
];

local profile = [
  kf.KustomizeConfig("profiles", overlays=["application", "istio", "agilestacks"],
    parameters=[
      kf.NameValue("userid-header", "kubeflow-userid"),
      kf.NameValue("admin", std.extVar("HUB_DEX_USER")),
    ]
  )
];

local kfdef = kf.Definition(name=std.extVar("HUB_COMPONENT"), namespace=kubeflowNamespace.value) {
  spec+: {
    repos: [
      kf.Repo("manifests", std.extVar("KF_REPO")),
      // kf.Repo("manifests", std.extVar("KF_TARBALL")),
      // kf.Repo("agilestacks", std.extVar("KF_KUSTOM_REPO")),
    ],
    applications+: []
      + metacontroller
      + istio 
      + certManager
      // + dex
      + argo 
      + admissionWebHook
      + centraldashboard
      // + spark 
      + metadata
      + jupyter
      + pytorch
      + kfserving
      // + spartakus
      + tensorboard
      + katib
      + pipeline
      + seldon
      + profile
  }
};

kfdef + {
  metadata+: {
    clusterName: std.extVar("HUB_DOMAIN_NAME"),
  },
  spec+: {
    version: std.extVar("HUB_COMPONENT_VERSION"),
    // useBasicAuth: false,
    // useIstio: false,
  },
}
