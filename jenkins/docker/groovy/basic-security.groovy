#!groovy

import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

println "--> creating local user 'admin'"

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin', 'secret')
instance.setSecurityRealm(hudsonRealm)

def secretsHome = System.getenv('JENKINS_SECRETS_HOME') ?: "/usr/share/jenkins/ref/secrets"
def secretsFile = new File(secretsHome, 'robot')
if (secretsFile.exists()) {
  secret = secretsFile.text.trim()
  hudsonRealm.createAccount('robot', secret)
  instance.setSecurityRealm(hudsonRealm)
}

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.save()
