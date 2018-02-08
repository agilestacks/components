#!/usr/bin/env groovy
import jenkins.model.*
import org.jenkinsci.plugins.workflow.libs.*
import hudson.plugins.filesystem_scm.*

def sharedLibsHome = System.getenv('SHARED_LIBS') ?: '/shared-libs'

def oldLibs = GlobalLibraries.get().libraries
def newLibs = (new File(sharedLibsHome).
  listFiles().findAll { file ->
    file.directory && oldLibs.find {file.name == it.name} == null
  }.collect { dir ->
    println "Register shared library: ${dir.name}@master from ${dir.path}"
    def scm = new FSSCM(dir.path, false, false, null)
    def lib = new LibraryConfiguration(dir.name, new SCMRetriever(scm))
    if (dir == 'default') {
      lib.implicit = true
    } else {
      lib.implicit = false      
    }
    lib.defaultVersion = 'master'
    lib.allowVersionOverride = true
    lib
  }
)
GlobalLibraries.get().libraries = (oldLibs + newLibs)
