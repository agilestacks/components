#!/usr/bin/env groovy

import jenkins.model.*
import java.util.logging.Logger
import java.io.*

import io.fabric8.kubernetes.client.*

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

def kubernetes = new DefaultKubernetesClient(new ConfigBuilder().build())
kubernetes.
  configMaps().
  withLabels([
    'project': 'jenkins',
    'qualifier': 'env-config'
  ]).
  list().
  items.each {
    envVars.putAll( it.data ?: [] )
  }

jenk.save()
