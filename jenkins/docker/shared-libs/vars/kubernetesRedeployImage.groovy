#!/usr/bin/env groovy

@Grab(group = 'io.fabric8', module = 'kubernetes-client', version = '2.6.1')
import io.fabric8.kubernetes.client.dsl.internal.DeploymentOperationsImpl
import io.fabric8.kubernetes.client.DefaultKubernetesClient



def call(def deploymentName, def dockerImage, def namespace = 'automation-hub') {
    def kubernetes = new DefaultKubernetesClient()
    def opts = kubernetes.
            extensions().
            deployments().
            inNamespace(namespace).
            withName(deploymentName)

    def imageWithoutVersion = dockerImage.split(':')[0]
    def deployment = opts.get()
    if (deployment == null) {
      error "Cannot find deployment: ${deploymentName} in namespace: ${namespace}"
    }
    deployment.spec.template.spec.containers.find({ it ->
        it.image.startsWith(imageWithoutVersion)
    }).each({ it ->
        it.image = dockerImage
    })
    def answer = opts.replace(deployment)
    echo "Update deployment: ${answer.status}"
    ((DeploymentOperationsImpl)opts).waitUntilDeploymentIsScaled(answer.status.replicas)
    echo "Done"
}
