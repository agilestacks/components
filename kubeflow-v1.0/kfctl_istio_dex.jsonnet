local kf                = import "kfctl.libsonnet";
local utils             = import "utils.libsonnet";

local istioNamespace    = kf.Parameter("namespace", "istio-system");
local ksystemNamespace  = kf.Parameter("namespace", "kube-system");
local certMgrNamespace  = kf.Parameter("namespace", "cert-manager");
local knativeNamespace  = kf.Parameter("namespace", "knative-serving");
local kubeflowNamespace = kf.Parameter("namespace", std.extVar("HUB_COMPONENT_NAMESPACE"));

// local name              = std.extVar("HUB_COMPONENT_NAME");
// local dexUrl = std.format("http://dex.%s.svc.cluster.local:5556/dex", kubeflowNamespace.value);
// local dexUrl      = std.extVar("HUB_OIDC_AUTH_URI");

local istioApps = [
  // kf.KustomizeConfig("istio/istio-crds", parameters=[istioNamespace]),
  // kf.KustomizeConfig("istio/istio-install", parameters=[istioNamespace]),
  kf.KustomizeConfig("istio/cluster-local-gateway", parameters=[istioNamespace]),
  kf.KustomizeConfig("istio/kfserving-gateway", parameters=[istioNamespace]),
  kf.KustomizeConfig("istio/istio", overlays=["agilestacks"],
    parameters=[kf.Parameter("clusterRbacConfig", "OFF")],
  ),
  kf.KustomizeConfig("istio/oidc-authservice", overlays=["application", "agilestacks"],
    parameters=[
      kf.Parameter("client_id",          std.extVar("HUB_OIDC_CLIENT_ID")),
      kf.Parameter("oidc_provider",      std.extVar("HUB_OIDC_AUTH_URI")),
      kf.Parameter("oidc_redirect_uri",  std.extVar("HUB_OIDC_REDIRECT_URI")),
      kf.Parameter("oidc_auth_url",      std.extVar("HUB_OIDC_AUTH_URI") + "/auth"),
      kf.Parameter("application_secret", std.extVar("HUB_OIDC_SECRET")),
      kf.Parameter("skip_auth_uri",      std.extVar("HUB_OIDC_AUTH_URI")),
      kf.Parameter("userid-header",      "kubeflow-userid"),
      // kf.Parameter("userid-prefix", ""),
      istioNamespace]),
  kf.KustomizeConfig("istio/add-anonymous-user-filter"),
];

local installCertManager = false;
local certManagerApps = if installCertManager then [
  kf.KustomizeConfig("cert-manager/cert-manager-crds", parameters=[certMgrNamespace],),
  kf.KustomizeConfig("cert-manager/cert-manager-kube-system-resources", parameters=[ksystemNamespace],),
  kf.KustomizeConfig("cert-manager/cert-manager", overlays=["self-signed", "application"], parameters=[certMgrNamespace],),
] else [];

local metacontrollerApps = [
  kf.KustomizeConfig("application/application-crds"),
  kf.KustomizeConfig("application/application", overlays=["application"],),
  kf.KustomizeConfig("metacontroller"),
];

local argoApps = [
  kf.KustomizeConfig("argo", overlays = ["istio", "application", "agilestacks"])
];

local centraldashboardApps = [
  kf.KustomizeConfig("common/centraldashboard", overlays=["istio", "application"]),
];

local metadataApps = [
  kf.KustomizeConfig("metadata", overlays=["istio", "db", "application"],),
];

local sparkApps = [
  kf.KustomizeConfig("spark/spark-operator", overlays=["application"]),
];

local pytorchApps = [
  kf.KustomizeConfig("pytorch-job/pytorch-job-crds", overlays=["application"]),
  kf.KustomizeConfig("pytorch-job/pytorch-operator", overlays=["application"]),
];

local kfservingApps = [
  kf.KustomizeConfig("knative/knative-serving-crds", overlays=["application"], parameters=[knativeNamespace]),
  kf.KustomizeConfig("knative/knative-serving-install", overlays=["application","agilestacks"], parameters=[knativeNamespace]),
  kf.KustomizeConfig("kfserving/kfserving-crds", overlays=["application"]),
  kf.KustomizeConfig("kfserving/kfserving-install", overlays=["application"]),
];

// local spartakusApps = [
//   kf.KustomizeConfig("common/spartakus", overlays=["application"],
//     parameters=[
//       kf.Parameter("usageId", std.md5(name)),
//       kf.Parameter("reportUsage", "false")
//     ],),
// ];

local jupyterApps = [
  kf.KustomizeConfig("jupyter/jupyter-web-app", overlays=["istio", "application"]),  
  kf.KustomizeConfig("jupyter/notebook-controller", overlays=["istio", "application"]),
];

local tensorboardApps = [
  kf.KustomizeConfig("tensorboard", overlays=["istio"]),
  kf.KustomizeConfig("tf-training/tf-job-crds", overlays=["application"]),
  kf.KustomizeConfig("tf-training/tf-job-operator", overlays=["application"]),
];

local katibApps = [
  kf.KustomizeConfig("katib/katib-crds", overlays=["application"]),
  kf.KustomizeConfig("katib/katib-controller", overlays=["istio", "application"]),
];

local pipelineApps = [
  kf.KustomizeConfig("pipeline/api-service", overlays=["application"]),
  kf.KustomizeConfig("pipeline/minio", overlays=["application"],
    parameters=[
      kf.Parameter("minioPvcName", "kf-"+std.extVar("HUB_COMPONENT")+"-minio")
    ]),
  kf.KustomizeConfig( "pipeline/mysql", overlays=["application"],
    parameters=[
      kf.Parameter("mysqlPvcName", "kf-"+std.extVar("HUB_COMPONENT")+"-minio")
    ]),
  kf.KustomizeConfig("pipeline/pipelines-runner", overlays=["application"]),
  kf.KustomizeConfig("pipeline/pipelines-ui", overlays=["istio", "application"]),
  kf.KustomizeConfig("pipeline/scheduledworkflow", overlays=["application"]),
  kf.KustomizeConfig("pipeline/pipeline-visualization-service", overlays=["application"]),
];

local seldonApps = [
  kf.KustomizeConfig("seldon/seldon-core-operator", overlays=["application"]),
];

local admissionWebHookApps = if installCertManager then [
  kf.KustomizeConfig("admission-webhook/webhook", overlays=["cert-manager", "application"]),
] else [
  kf.KustomizeConfig("admission-webhook/bootstrap", overlays=["application"]),
  kf.KustomizeConfig("admission-webhook/webhook", overlays=["application"]),
];

local profileApps = [
  kf.KustomizeConfig("profiles", overlays=["application", "istio"],
    parameters=[
      kf.Parameter("userid-header", "kubeflow-userid"),
      kf.Parameter("admin", std.extVar("HUB_DEX_USER")),
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
      + metacontrollerApps
      + istioApps 
      + certManagerApps
      // + dexApps
      + argoApps 
      + admissionWebHookApps
      + centraldashboardApps
      // + sparkApps 
      + metadataApps
      + jupyterApps
      + pytorchApps
      + kfservingApps
      // + spartakusApps
      + tensorboardApps
      + katibApps
      + pipelineApps
      + seldonApps
      + profileApps
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
