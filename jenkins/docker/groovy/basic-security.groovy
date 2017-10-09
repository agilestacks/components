#!groovy

import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

println "--> creating local user 'admin'"

def adminUser     = System.getenv('ADMIN_USER')     ?: "admin"
def adminPassword = System.getenv('ADMIN_PASSWORD') ?: "secret"
def hudsonRealm   = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount(adminUser, adminPassword)

def saUser     = System.getenv('SERVICE_ACCOUNT_USER')
def saPassword = System.getenv('SERVICE_ACCOUNT_PASSWORD')
if (saUser != null) {
  hudsonRealm.createAccount(saUser, saPassword)
}
instance.securityRealm = hudsonRealm

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.save()

