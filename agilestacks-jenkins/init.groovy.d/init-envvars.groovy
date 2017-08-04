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

if (envVarsNodePropertyList == null || envVarsNodePropertyList.empty) {
  globalProps << new hudson.slaves.EnvironmentVariablesNodeProperty()
}

def envVars = envVarsNodePropertyList[0]
  
def conf =  new DefaultKubernetesClient(new ConfigBuilder().build()).
                  configMaps().
                  inNamespace(namespace).
                  withName('agilestacks').get().data

envVars << conf
jenk.save()
