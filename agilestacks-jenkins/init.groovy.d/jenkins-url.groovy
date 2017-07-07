#!/usr/bin/env groovy

import jenkins.model.*
import java.util.logging.Logger

def log = Logger.getLogger(this.class.name)

// override jenkins
def jlc = JenkinsLocationConfiguration.get()
jlc.setUrl('${jenkins_url}') // changed during provisioning
jlc.setAdminAddress('dev@agilestacks.com') // changed during provisioning
log.info('Override Jenkins URL to ${jenkins_url}')
jlc.save()
