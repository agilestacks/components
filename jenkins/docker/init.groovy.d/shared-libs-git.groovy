#!/usr/bin/env groovy
import jenkins.model.*
import org.jenkinsci.plugins.workflow.libs.*
import jenkins.plugins.git.*
import io.fabric8.kubernetes.client.*

def DEFAULT_LIB = [
  NAME:           'agilestacks',
  REMOTE:         'https://github.com/agilestacks/jenkins.git',
  CREDENTIALS_ID: '',
  REMOTE_NAME:    'origin',
  REF_SPECS:      '+refs/heads/*:refs/remotes/origin/*',
  INCLUDES:       '*',
  EXCLUDES:       '',
  DEFAULT_VERSION:'master'
]

def configs = []
def oldLibs = GlobalLibraries.get().libraries
def client = new DefaultKubernetesClient(new ConfigBuilder().build())
if (client.masterUrl && client.namespace) {
  configs += client.
                configMaps().
                withLabels([
                  'project': 'jenkins',
                  'qualifier': 'shared-lib',
                  'type': 'git'
                ]).
                list().
                items.
                grep { it.data }.
                collect { DEFAULT_LIB + [NAME: it.name] + it.data }
}

if ( !configs.find { it.name == DEFAULT_LIB.NAME } ) {
  configs << DEFAULT_LIB
}

def newLibs = configs.collect { conf ->
  def name = conf.NAME
  def scm = new GitSCMSource( UUID.randomUUID().toString(),
                              conf.REMOTE,
                              conf.CREDENTIALS_ID,
                              conf.REMOTE_NAME,
                              conf.REF_SPECS,
                              conf.INCLUDES,
                              conf.EXCLUDES,
                              true )

  def lib = new LibraryConfiguration(name, new SCMSourceRetriever(scm))
  lib.defaultVersion = conf.DEFAULT_VERSION ?: 'master'
  lib.implicit = conf.IMPLICIT ?: (name == DEFAULT_LIB.NAME)
  lib.allowVersionOverride = true
  lib.includeInChangesets = true
  lib
}.grep { lib ->
  !oldLibs.find { it.name == lib.name }
}

GlobalLibraries.get().libraries = (oldLibs + newLibs)
