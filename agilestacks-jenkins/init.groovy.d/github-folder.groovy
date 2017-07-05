#!/usr/bin/env groovy

import jenkins.branch.OrganizationFolder
import org.jenkinsci.plugins.github_branch_source.*

import jenkins.*
import jenkins.model.*
import hudson.*
import hudson.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.*
import org.jenkinsci.plugins.github.config.*
import jenkins.branch.BranchIndexingCause;
import java.util.logging.Logger

def log = Logger.getLogger(this.class.name)
def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
def domain = Domain.global()
def secretsHome = System.getenv('JENKINS_SECRETS_HOME') ?: '/usr/share/jenkins/ref/secrets'
def secretsFile = new File(secretsHome, 'github-token.txt')

def userPass
if (secretsFile.exists()) {
  def credentials = new org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl(
    CredentialsScope.GLOBAL,
    'github-secret',
    'GitHub deployment keys',
    new hudson.util.Secret( secretsFile.text.trim() ))
  store.addCredentials(domain, credentials)

  userPass = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "github-user", "Github deployment keys",
    "admin",
    secretsFile.text.trim()
  )
  store.addCredentials(domain, userPass)

  def githubs = GitHubPluginConfig.all().get(GitHubPluginConfig.class)
  githubs.configs << new GitHubServerConfig( credentials.id )
  githubs.save()
  log.info("GitHub has been configured successfully based on secret from: ${secretsFile.path}")
} else {
  log.warning("Cannot find GitHub token in ${secretsFile.path}. Your github has not been configured")
}


def jenk = Jenkins.instance
def ofs = jenk.getAllItems(OrganizationFolder)
if (!ofs.any { it.name == 'agilestacks' }) {

  def nav = new GitHubSCMNavigator('https://api.github.com', 'agilestacks', userPass.id, 'SAME')
  nav.includes = 'master'

  def gh = jenk.createProject(OrganizationFolder, 'agilestacks')
  gh.description = 'Agile Stacks Inc, Github Organization'
  gh.navigators << nav
  gh.scheduleBuild(0, new BranchIndexingCause())
  jenk.save()
}
