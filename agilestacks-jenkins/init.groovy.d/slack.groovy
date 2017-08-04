#!/usr/bin/env groovy

import jenkins.model.*
import java.util.logging.Logger
import java.io.*

import io.fabric8.kubernetes.api.model.NamespaceBuilder
import io.fabric8.kubernetes.client.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.*

def namespace = new File("/var/run/secrets/kubernetes.io/serviceaccount/namespace").text

def jenk = Jenkins.instance
def globalProps = jenk.globalNodeProperties
  
def conf =  new DefaultKubernetesClient(new ConfigBuilder().build()).
                  configMaps().
                  inNamespace(namespace).
                  withName('agilestacks').get().data

def log = Logger.getLogger(this.class.name)
def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
def domain = Domain.global()

def credentials = new org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl(
  CredentialsScope.GLOBAL,
  'slack-secret',
  'Slack integration token',
  new hudson.util.Secret(conf.SLACK_TOKEN))
//store.addCredentials(domain, credentials)
//jenk.save()

