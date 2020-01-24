local kf               = import "lib/kfctl.libsonnet";

local istioNamespace    = kf.Parameter("namespace", "istio-system");
local knativeNamespace  = kf.Parameter("namespace", "knative-serving");
local kubeflowNamespace = kf.Parameter("namespace", std.extVar("HUB_COMPONENT_NAMESPACE"));
local userIdHeader      = kf.Parameter("userid-header", "kubeflow-userid");
local version           = std.extVar("HUB_COMPONENT_VERSION");
local name              = std.extVar("HUB_COMPONENT_NAMESPACE");

local dexUrl = std.format("http://dex.%s.svc.cluster.local:5556/dex", kubeflowNamespace.value);
// local dexUrl           = std.extVar("HUB_DEX_URL");
local uuid              = std.md5(name);
local adminEmail        = "support@agilestacks.com";
local ingressHost       = std.join(".", [name, std.extVar("HUB_DOMAIN_NAME")]);
local ingressgateway    = "ingressgateway";

local installArgo        = true;
local installPytorch     = true;
local installKfServing   = true;
local installTensorboard = true; 
local installMinio       = true;
local installSeldonCore  = true;
local installMySQL       = true;

kf.Definition(name=name, namespace=kubeflowNamespace.value) {
  spec+: {
    version: "v0.8-branch",
    useBasicAuth: false,
    useIstio: false,
    applications: [
      kf.KustomizeConfig("application/application-crds"),
      kf.KustomizeConfig("application/application", overlays=["application"],),
      kf.KustomizeConfig("metacontroller"),
      kf.KustomizeConfig("istio/istio-crds", parameters=[istioNamespace]),
      // kf.KustomizeConfig("istio/istio-install", parameters=[istioNamespace],),
      kf.KustomizeConfig("istio",
        repoName="agilestacks",
        parameters=[
          kf.Parameter("clusterRbacConfig", "OFF"),
          kf.Parameter("gatewaySelector", ingressgateway),
          kf.Parameter("ingressHost", ingressHost),
        ]
      ),
      kf.KustomizeConfig("istio/oidc-authservice",
        overlays=["application"],
        parameters=[
          kubeflowNamespace,
          // istioNamespace,
          userIdHeader,
          kf.Parameter("oidc_provider", dexUrl),
          kf.Parameter("oidc_redirect_uri", "/login/oidc"),
          kf.Parameter("oidc_auth_url", "/dex/auth"),
          kf.Parameter("skip_auth_uri", "/dex"),
          kf.Parameter("client_id", "kubeflow-oidc-authservice")
        ],
      ),
      kf.KustomizeConfig("dex-auth/dex-crds",
        overlays=["istio"],
        parameters=[
          kf.Parameter("namespace", "kubeflow"),
          kf.Parameter("issuer", dexUrl),
          kf.Parameter("client_id", "kubeflow-oidc-authservice"),
          kf.Parameter("oidc_redirect_uris", '["/login/oidc"]'),
          kf.Parameter("static_email", adminEmail),
          # Password is "12341234", 12-round bcrypt-hashed.
          kf.Parameter("static_password_hash", "$2y$12$ruoM7FqXrpVgaol44eRZW.4HWS8SAvg6KYVVSCIwKQPBmTpCm.EeO"),
        ],
      ),
      kf.KustomizeConfig("kubeflow-roles",),
    ] + if installArgo then [
      kf.KustomizeConfig("argo", overlays=["istio", "application"],),
    ] + [
      kf.KustomizeConfig("common/centraldashboard", overlays=["istio", "application"],),
      kf.KustomizeConfig("admission-webhook/bootstrap", overlays=["application"],),
      kf.KustomizeConfig("admission-webhook/webhook", overlays=["application"]),
      kf.KustomizeConfig("jupyter/jupyter-web-app",
        overlays=["istio", "application"],
        parameters=[userIdHeader],
      ),
      kf.KustomizeConfig("metadata", overlays=["istio", "application"]),
      kf.KustomizeConfig("jupyter/notebook-controller", overlays=["istio", "application"]),
    ] + if installPytorch then [
      kf.KustomizeConfig("pytorch-job/pytorch-job-crds", overlays=["application"]),
      kf.KustomizeConfig("pytorch-job/pytorch-operator", overlays=["application"]),
    ] + if installKfServing then [
      kf.KustomizeConfig("knative/knative-serving-crds",
        name="knative-crds",
        overlays=["application"],
        parameters=[knativeNamespace],
      ),
      kf.KustomizeConfig("knative/knative-serving-install",
        name="knative-install",
        overlays=["application"],
        parameters=[knativeNamespace],
      ),
      kf.KustomizeConfig("kfserving/kfserving-crds",overlays=["application"]),
      kf.KustomizeConfig("kfserving/kfserving-install",overlays=["application"]),
    ] +
    // [
      // kf.KustomizeConfig("common/spartakus",
      //   overlays=["application"],
      //   parameters=[kf.Parameter("usageId", uuid), kf.Parameter("reportUsage", "true")]
      // ),
      // ]
    if installTensorboard then [
      kf.KustomizeConfig("tensorboard", overlays=["istio"]),
    ] + [
      kf.KustomizeConfig("tf-training/tf-job-crds", overlays=["application"]),
      kf.KustomizeConfig("tf-training/tf-job-operator", overlays=["application"]),
      kf.KustomizeConfig("katib/katib-crds", overlays=["application"]),
      kf.KustomizeConfig("katib/katib-controller", overlays=["application", "istio"]),
    ] + if installMinio then [
      kf.KustomizeConfig("pipeline/minio",
        overlays=["application"],
        parameters=[kf.Parameter("minioPvcName", "minio-pv-claim")]
      ),
    ] + if installMySQL then [
      kf.KustomizeConfig("pipeline/mysql",
        overlays=["application"],
        parameters=[kf.Parameter("mysqlPvcName", "mysql-pv-claim")]
      ),
    ] + [
      kf.KustomizeConfig("pipeline-api-service", repoName="agilestacks", overlays=["application"]),
      kf.KustomizeConfig("pipeline/persistent-agent", overlays=["application"]),
      kf.KustomizeConfig("pipeline/pipelines-runner", overlays=["application"]),
      kf.KustomizeConfig("pipeline/pipelines-ui", overlays=["istio", "application"]),
      kf.KustomizeConfig("pipeline/pipelines-viewer", overlays=["application"]),
      kf.KustomizeConfig("pipeline/scheduledworkflow", overlays=["application"]),
      kf.KustomizeConfig("pipeline/pipeline-visualization-service", overlays=["application"]),
      kf.KustomizeConfig("profiles",
        overlays=["application", "istio"],
        parameters=[userIdHeader],
        // parameters=[kf.Parameter("admin", adminEmail)]
      ),
    ] + if installSeldonCore then [
      kf.KustomizeConfig("seldon/seldon-core-operator", overlays=["application"]),
    ] ,
    repos: [
      kf.Repo("manifests", std.extVar("KF_REPO")),
      // kf.Repo("manifests", std.extVar("KF_TARBALL")),
      kf.Repo("agilestacks", std.extVar("KF_KUSTOM_REPO")),
    ],
  }
}
