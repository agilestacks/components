#!/usr/bin/env groovy

import jenkins.model.*
import java.util.logging.Logger

import io.fabric8.kubernetes.api.model.NamespaceBuilder
import io.fabric8.kubernetes.client.*

def kubeClient() {
    return new DefaultKubernetesClient(new ConfigBuilder().withNamespace('automation-hub').build())
}

// def jsonFile  = kubeClient().
//                   configMaps().
//                   inNamespace('automation-hub').
//                   withName('jenkins').get().data['cloud.json']
// def slurper = new groovy.json.JsonSlurper()
// def conf  = slurper.parseText(jsonFile)

def jenk = Jenkins.instance
def globalProps = jenk.globalNodeProperties
def envVarsNodePropertyList = globalProps.envVars

//if (envVarsNodePropertyList == null) {
//  envVarsNodePropertyList = new hudson.slaves.EnvironmentVariablesNodeProperty()
//}

if ( envVarsNodePropertyList.empty ) {
  envVarsNodePropertyList << [:]
}


def envVars = envVarsNodePropertyList[0]
  
def facts =  kubeClient().
                  configMaps().
                  inNamespace('jenkins').
                  withName('agilestacks').get().data

envVars << facts
jenk.save()

//automationHubImage    = conf.automation_hub_image
//automationHubEndpoint = conf.automation_hub_endpoint