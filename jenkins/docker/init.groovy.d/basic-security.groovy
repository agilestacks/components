#!groovy

import jenkins.model.*
import hudson.security.*
import java.util.logging.Logger

def userRegistered = false

def log     = Logger.getLogger(this.class.name)
def jenkins = Jenkins.getInstance()

def adminUser     = System.getenv('ADMIN_USER')     ?: "admin"
def adminPassword = System.getenv('ADMIN_PASSWORD') ?: "secret"
jenkins.securityRealm = new HudsonPrivateSecurityRealm(false)
if (adminUser != null && adminPassword != null) {
  jenkins.securityRealm.createAccount(adminUser, adminPassword)
  log.info("Added user: ${adminUser}")
  userRegistered = true
}

def saUser     = System.getenv('SERVICE_ACCOUNT_USER')
def saPassword = System.getenv('SERVICE_ACCOUNT_PASSWORD')
if (saUser != null && saPassword != null) {
  jenkins.securityRealm.createAccount(saUser, saPassword)
  log.info("Added user: ${saUser}")
  userRegistered = true
}

if (userRegistered) {
  jenkins.authorizationStrategy = new FullControlOnceLoggedInAuthorizationStrategy()
  jenkins.authorizationStrategy.allowAnonymousRead = false
  jenkins.save()
}
