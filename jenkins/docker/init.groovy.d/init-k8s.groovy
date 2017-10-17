#!/usr/bin/env groovy

import jenkins.*
import jenkins.model.*
import hudson.*
import hudson.model.*
import org.csanchez.jenkins.plugins.kubernetes.*
import org.csanchez.jenkins.plugins.kubernetes.volumes.*
import org.csanchez.jenkins.plugins.kubernetes.volumes.workspace.*

import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*

def jenk     = Jenkins.instance
def k8sHost  = System.getenv('KUBERNETES_SERVICE_HOST')
def k8sPort  = System.getenv('KUBERNETES_SERVICE_PORT') ?: '443'
def creds    = jenk.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0]
def k8sCreds = creds.credentials.find {it instanceof TokenProducer}
if (k8sCreds == null) {
  k8sCreds  = new ServiceAccountCredential(
    CredentialsScope.GLOBAL,
    'default',
    'Default service account for Kubrnetes')
  creds.store.addCredentials(Domain.global(), k8sCreds)
}

def jenkHost  = System.getenv('JENKINS_SERVICE_HOST')
def jenkPort  = System.getenv('JENKINS_SERVICE_PORT') ?: '8080'
def jenkJnlp  = System.getenv('JENKINS_SERVICE_JNLP') ?: '50000'

def namespaceFile  = new File('/var/run/secrets/kubernetes.io/serviceaccount/namespace')
def kube           = new KubernetesCloud('kubernetes')
kube.serverUrl     = "${k8sPort == '443' ? 'https' : 'http'}://${k8sHost}:${k8sPort}/"
kube.skipTlsVerify = kube.serverUrl.startsWith('https')
kube.namespace     = namespaceFile.exists() ? namespaceFile.text : "default"
kube.credentialsId = k8sCreds.id
kube.jenkinsUrl    = "${jenkPort == '443' ? 'https' : 'http'}://${jenkHost}:${jenkPort}/"
kube.jenkinsTunnel = "${jenkHost}:${jenkJnlp}"
kube.defaultsProviderTemplate = 'agilestacks'

def pod         = new PodTemplate()
pod.name        = 'agilestacks'
pod.label       = 'agilestacks'
pod.annotations = [
  new PodAnnotation("provider", "agilestacks.com"),
  new PodAnnotation("project",  "jenkins"),
  new PodAnnotation("qualifier", "pod"),
  new PodAnnotation("type", "node")
]
// pod.customWorkspaceVolumeEnabled = true
// pod.workspaceVolume  = new PersistentVolumeClaimWorkspaceVolume('workspace-volume', false)
pod.volumes          = [
  new EmptyDirVolume('/home/jenkins', false),
  new PersistentVolumeClaim('/home/jenkins/workspace', 'workspace-volume', false),
  // new PersistentVolumeClaim('/home/jenkins/secrets', 'secrets-volume', true),
  // new HostPathVolume("/var/run/docker.sock", "/var/run/docker.sock")
  new EmptyDirVolume('/var/lib/docker', false)
]

// def container        = new ContainerTemplate('jnlp', 'jenkinsci/jnlp-slave:alpine')
def jnlp             = new ContainerTemplate('jnlp', 'docker.io/agilestacks/jenkins-slave:2.46.1-1')
jnlp.command         = ''
jnlp.args            = '${computer.jnlpmac} ${computer.name}'
jnlp.ttyEnabled      = false
jnlp.privileged      = false
jnlp.alwaysPullImage = true

def dind             = new ContainerTemplate('dind', 'docker.io/docker:dind')
dind.command         = 'dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 --storage-driver=overlay'
dind.ttyEnabled      = true
dind.privileged      = true
dind.alwaysPullImage = true

def kctl             = new ContainerTemplate('kubectl', 'docker.io/agilestacks/kubectl:1.6.1')
kctl.command         = 'cat'
kctl.ttyEnabled      = true

pod.containers  = [ jnlp, dind, kctl ]
kube.templates  = [ pod ]

jenk.clouds << kube
jenk.save()
