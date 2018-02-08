#!/usr/bin/env groovy

import jenkins.*
import jenkins.model.*
import hudson.*
import hudson.model.*
import org.csanchez.jenkins.plugins.kubernetes.*
import org.csanchez.jenkins.plugins.kubernetes.model.*
import org.csanchez.jenkins.plugins.kubernetes.volumes.*
import org.csanchez.jenkins.plugins.kubernetes.volumes.workspace.*
import io.fabric8.kubernetes.client.*

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

def configVars = [
  BACKEND_BUCKET_NAME:   'unset',
  BACKEND_BUCKET_REGION: 'us.east-1',
  BASE_DOMAIN:           'superhub.io',
  DNS_NAME:              'unset'
]

def client = new DefaultKubernetesClient(new ConfigBuilder().build())
if (client.masterUrl && client.namespace) {
  client.
    configMaps().
    withLabels([
      'project': 'jenkins',
      'qualifier': 'env-config'
    ]).
    list().
    items.each {
      configVars.putAll( it.data ?: [:] )
    }
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

// def container        = new ContainerTemplate('jnlp', 'jenkinsci/jnlp-slave:alpine')
def jnlp             = new ContainerTemplate('jnlp', 'docker.io/agilestacks/jenkins-slave:2.46.1-1')
jnlp.command         = ''
jnlp.args            = '${computer.jnlpmac} ${computer.name}'
jnlp.ttyEnabled      = false
jnlp.privileged      = false
jnlp.alwaysPullImage = true

def toolbox             = new ContainerTemplate('jnlp', 'docker.io/agilestacks/toolbox:stable')
toolbox.command         = 'cat'
toolbox.ttyEnabled      = true
toolbox.privileged      = true
toolbox.alwaysPullImage = true

def kctl             = new ContainerTemplate('kubectl', 'docker.io/agilestacks/kubectl:1.6.1')
kctl.command         = 'cat'
kctl.ttyEnabled      = true
kctl.alwaysPullImage = true

def dind             = new ContainerTemplate('dind', 'docker.io/docker:dind')
dind.command         = 'dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 --storage-driver=overlay'
dind.ttyEnabled      = true
dind.privileged      = true
dind.alwaysPullImage = true

def pod1         = new PodTemplate()
pod1.name        = 'default'
pod1.label       = pod1.name
pod1.annotations = [
  new PodAnnotation("provider", "agilestacks.com"),
  new PodAnnotation("project",  "jenkins"),
  new PodAnnotation("qualifier", "pod"),
  new PodAnnotation("type", "node")
]
pod1.volumes          = [
  new EmptyDirVolume('/home/jenkins', false),
  new PersistentVolumeClaim('/home/jenkins/workspace', 'workspace-volume', false),
  new EmptyDirVolume('/var/lib/docker', false)
]

pod1.containers  = [ jnlp ]

def pod2         = new PodTemplate()
pod2.name        = 'toolbox'
pod2.envVars     = [
  new KeyValueEnvVar('BACKEND_BUCKET_NAME', configVars.BACKEND_BUCKET_NAME),
  new KeyValueEnvVar('BACKEND_BUCKET_REGION', configVars.BACKEND_BUCKET_REGION),
  new KeyValueEnvVar('BASE_DOMAIN', configVars.BASE_DOMAIN),
  new KeyValueEnvVar('DNS_NAME', configVars.DNS_NAME)
]
pod2.label       = pod2.name
pod2.containers  = [ toolbox ]
pod2.volumes          = [
  new HostPathVolume("/var/run/docker.sock", "/var/run/docker.sock")
]

def pod3         = new PodTemplate()
pod3.name        = 'agilestacks'
pod3.label       = pod3.name
pod3.containers  = [ kctl, dind ]
pod3.volumes          = [
  new HostPathVolume("/var/run/docker.sock", "/var/run/docker.sock")
]

def pod1and2 = PodTemplateUtils.combine(pod1, pod2)
def pod1and2and3 = PodTemplateUtils.combine(pod1and2, pod3)

kube.templates  = [ pod1, pod1and2, pod1and2and3]

jenk.clouds << kube
jenk.save()
