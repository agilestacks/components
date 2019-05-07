{
  local k = import "k.libsonnet",
  local util = import "kubeflow/common/util.libsonnet",
  new(_env, _params):: {
    local params = _params + _env,

    local ambassadorService = {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        labels: {
          service: "ambassador",
        },
        name: "ambassador",
        namespace: params.namespace,
        annotations:
          if params.ambassadorProtocol == "https" then {
          "getambassador.io/config":
            std.join("\n", [
              "---",
              "apiVersion: ambassador/v0",
              "kind:  Module",
              "name: ambassador",
              "config:",
              " use_proxy_proto: true",
              " use_remote_address: true",
              "---",
              "apiVersion: ambassador/v1",
              "kind: Module",
              "name: tls",
              "config:",
              " server:",
              "   enabled: true",
              "   redirect_cleartext_from: 8080",
            ]),
          "service.beta.kubernetes.io/aws-load-balancer-ssl-ports": "443",
          "service.beta.kubernetes.io/aws-load-balancer-ssl-cert": params.ambassadorAcmCertificateArn,
          "service.beta.kubernetes.io/aws-load-balancer-backend-protocol": "tcp",
          "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled": "true",
          "service.beta.kubernetes.io/aws-load-balancer-proxy-protocol": "*",
        } else {},
      },
      spec: {
        ports:
        if params.ambassadorProtocol == "https" then [
          {
            name: "ambassador-tls",
            port: 443,
            targetPort: 443,
          },
          {
            name: "ambassador-redirect",
            port: 80,
            targetPort: 8080,
          },
        ]
        else [
          {
            name: "ambassador",
            port: 80,
            targetPort: 80,
            [if (params.ambassadorServiceType == 'NodePort') &&
                (params.ambassadorNodePort >= 30000) &&
                (params.ambassadorNodePort <= 32767)
             then 'nodePort']: params.ambassadorNodePort,
          },
        ],
        selector: {
          service: "ambassador",
        },
        type: params.ambassadorServiceType,
      },
    },  // service
    ambassadorService:: ambassadorService,

    local adminService = {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        labels: {
          service: "ambassador-admin",
        },
        name: "ambassador-admin",
        namespace: params.namespace,
      },
      spec: {
        ports: [
          {
            name: "ambassador-admin",
            port: 8877,
            targetPort: 8877,
          },
        ],
        selector: {
          service: "ambassador",
        },
        type: "ClusterIP",
      },
    },  // adminService
    adminService:: adminService,

    local ambassadorRole = {
      apiVersion: "rbac.authorization.k8s.io/v1beta1",
      kind: "ClusterRole",
      metadata: {
        name: "ambassador",
      },
      rules: [
        {
          apiGroups: [
            "",
          ],
          resources: [
            "services",
          ],
          verbs: [
            "get",
            "list",
            "watch",
          ],
        },
        {
          apiGroups: [
            "",
          ],
          resources: [
            "configmaps",
          ],
          verbs: [
            "create",
            "update",
            "patch",
            "get",
            "list",
            "watch",
          ],
        },
        {
          apiGroups: [
            "",
          ],
          resources: [
            "secrets",
          ],
          verbs: [
            "get",
            "list",
            "watch",
          ],
        },
      ],
    },  // role
    ambassadorRole:: ambassadorRole,

    local ambassadorServiceAccount = {
      apiVersion: "v1",
      kind: "ServiceAccount",
      metadata: {
        name: "ambassador",
        namespace: params.namespace,
      },
    },  // serviceAccount
    ambassadorServiceAccount:: ambassadorServiceAccount,

    local ambassadorRoleBinding = {
      apiVersion: "rbac.authorization.k8s.io/v1beta1",
      kind: "ClusterRoleBinding",
      metadata: {
        name: "ambassador",
      },
      roleRef: {
        apiGroup: "rbac.authorization.k8s.io",
        kind: "ClusterRole",
        name: "ambassador",
      },
      subjects: [
        {
          kind: "ServiceAccount",
          name: "ambassador",
          namespace: params.namespace,
        },
      ],
    },  // roleBinding
    ambassadorRoleBinding:: ambassadorRoleBinding,

    local ambassadorDeployment = {
      apiVersion: "apps/v1beta1",
      kind: "Deployment",
      metadata: {
        name: "ambassador",
        namespace: params.namespace,
      },
      spec: {
        replicas: params.replicas,
        template: {
          metadata: {
            labels: {
              service: "ambassador",
            },
            namespace: params.namespace,
          },
          spec: {
            containers: [
              {
                env: [
                  {
                    name: "AMBASSADOR_NAMESPACE",
                    valueFrom: {
                      fieldRef: {
                        fieldPath: "metadata.namespace",
                      },
                    },
                  },
                ],
                image: params.ambassadorImage,
                name: "ambassador",
                resources: {
                  limits: {
                    cpu: 1,
                    memory: "400Mi",
                  },
                  requests: {
                    cpu: "200m",
                    memory: "100Mi",
                  },
                },
                readinessProbe: {
                  httpGet: {
                    path: "/ambassador/v0/check_ready",
                    port: 8877,
                  },
                  initialDelaySeconds: 30,
                  periodSeconds: 30,
                },
                livenessProbe: {
                  httpGet: {
                    path: "/ambassador/v0/check_alive",
                    port: 8877,
                  },
                  initialDelaySeconds: 30,
                  periodSeconds: 30,
                },
              },
            ],
            restartPolicy: "Always",
            serviceAccountName: "ambassador",
          },
        },
      },
    },  // deploy
    ambassadorDeployment:: ambassadorDeployment,

    parts:: self,
    all:: [
      self.ambassadorService,
      self.adminService,
      self.ambassadorRole,
      self.ambassadorServiceAccount,
      self.ambassadorRoleBinding,
      self.ambassadorDeployment,
    ],

    list(obj=self.all):: util.list(obj),
  },
}
