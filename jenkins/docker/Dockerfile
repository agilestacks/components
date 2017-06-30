FROM jenkinsci/jenkins:2.46.1-alpine
MAINTAINER Antons Kranga <anton@agilestacks.com>

ENV JENKINS_SLAVE_AGENT_PORT  50000
ENV JENKINS_SECRETS_HOME      /usr/share/jenkins/ref/secrets
ENV JENKINS_OPTS              -Djava.awt.headless=true
# ENV JENKINS_OPTS -Dhudson.footerURL=http://agilestacks.com -Djenkins.slaves.JnlpSlaveAgentProtocol3.enabled=true -Djenkins.security.ApiTokenProperty.showTokenToAdmins=true
ENV JAVA_OPTS "-Dhudson.model.UpdateCenter.never=true -Dhudson.model.DirectoryBrowserSupport.CSP=\"default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';\" -Djenkins.model.DirectoryBrowserSupport.CSP=\"default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';\""
ENV SCRIPT_APPROVAL_DIR        /usr/share/jenkins/ref/approval.d
ENV CONFIG_DIR                /usr/share/jenkins/ref/config.d

USER root
COPY plugins.txt               /plugins.txt
COPY groovy/*.groovy           /usr/share/jenkins/ref/init.groovy.d/
COPY etc/disable-wizard        /usr/share/jenkins/ref/jenkins.install.InstallUtil.lastExecVersion
COPY etc/config.txt            ${CONFIG_DIR}/example.txt
COPY script-approval.txt       ${SCRIPT_APPROVAL_DIR}/initial.txt
# COPY etc/scriptApproval.xml    /usr/share/jenkins/ref/scriptApproval.xml
COPY etc/slave-to-master       ${JENKINS_SECRETS_HOME}/slave-to-master-security-kill-switch
COPY etc/insecure-robot.secret ${JENKINS_SECRETS_HOME}/robot
# COPY etc/*.conf               /usr/share/jenkins/ref/secreds/whitelisted-callables.d/*.conf

RUN  /usr/local/bin/plugins.sh /plugins.txt

COPY plugins/*.hpi            /usr/share/jenkins/ref/plugins/

RUN chown -R jenkins:jenkins  /usr/share/jenkins/ref && \
    mkdir -p ${JENKINS_SECRETS_HOME} && \
    chown -R jenkins:jenkins  ${JENKINS_SECRETS_HOME}

VOLUME /usr/share/secrets

USER jenkins

EXPOSE 8080
EXPOSE 50000

USER jenkins
