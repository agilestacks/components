#!/usr/bin/env groovy

import jenkins.model.*
import java.util.logging.Logger
import java.io.*

import io.fabric8.kubernetes.api.model.NamespaceBuilder
import io.fabric8.kubernetes.client.*


def namespace = new File("/var/run/secrets/kubernetes.io/serviceaccount/namespace").text

def jenk = Jenkins.instance
def globalProps = jenk.globalNodeProperties
def envVarsNodePropertyList = globalProps.envVars

def envVars
if (envVarsNodePropertyList == null || envVarsNodePropertyList.empty) {
  def envVarProps = new hudson.slaves.EnvironmentVariablesNodeProperty()
  globalProps.add( envVarProps )
  envVars = envVarProps.envVars
} else {
  envVars = envVarsNodePropertyList[0]
}
  
def conf =  new DefaultKubernetesClient(new ConfigBuilder().build()).
                  configMaps().
                  inNamespace(namespace).
                  withName('agilestacks').get().data

envVars.putAll( conf )
jenk.save()
