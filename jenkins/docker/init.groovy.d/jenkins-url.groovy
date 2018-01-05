#!/usr/bin/env groovy

import jenkins.model.*
import java.util.logging.Logger

def log   = Logger.getLogger(this.class.name)
def url   = System.getenv('JENKINS_URL')
def email = System.getenv('ADMIN_EMAIL')

// override jenkins
def jlc = JenkinsLocationConfiguration.get()
jlc.setUrl( url )
jlc.setAdminAddress(email) 
log.info("Override Jenkins URL to $url")
jlc.save()

log.info("Jenkins URL is now: ${Jenkins.instance.rootUrl}")
