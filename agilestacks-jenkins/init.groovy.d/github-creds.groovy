#!/usr/bin/env groovy

import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.*
import org.jenkinsci.plugins.github.config.*
import com.cloudbees.plugins.credentials.impl.*
import java.util.logging.Logger

def log = Logger.getLogger(this.class.name)

domain = Domain.global()
store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// def secretsHome = System.getenv('JENKINS_SECRETS_HOME') ?: '//usr/share/jenkins/ref/agilestacks/api-key.txt'
// def secretsFile = new File(secretsHome, 'github-key.txt')
// if (secretsFile.exists()) {
def credentials = new org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl(
  CredentialsScope.GLOBAL,
  'github-secret',
  'GitHub deployment keys',
   new hudson.util.Secret( System.getenv("GITHUB_DEPLOY_KEY") ))
store.addCredentials(domain, credentials)

userPass = new UsernamePasswordCredentialsImpl(
  CredentialsScope.GLOBAL,
  "github-user", "Github deploymen keys",
  "admin",
  System.getenv("GITHUB_DEPLOY_KEY") )
  //secretsFile.text.trim()
store.addCredentials(domain, userPass)

def githubs = GitHubPluginConfig.all().get(GitHubPluginConfig.class)
githubs.configs << new GitHubServerConfig( credentials.id )
githubs.save()
log.info("GitHub has been configured successfully based on secret from: GITHUB_DEPLOY_KEY")
// } else {
//   log.warning("Cannot find GitHub token in ${secretsFile.path}. Your github has not been configured")
// }
