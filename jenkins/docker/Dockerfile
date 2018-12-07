FROM jenkins/jenkins:lts-alpine
MAINTAINER Antons Kranga <anton@agilestacks.com>

ARG UC_DISABLED=true
ARG PERMISSIVE_SCRIPTS=false

ENV JAVA_OPTS                " -Dpermissive-script-security.enabled=${PERMISSIVE_SCRIPTS} \
                               -Dhudson.model.UpdateCenter.never=${UC_DISABLED} \
                               -Djenkins.install.runSetupWizard=false \
                               -Dhudson.model.DirectoryBrowserSupport.CSP=\"default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';\" \
                               -Djenkins.model.DirectoryBrowserSupport.CSP=\"default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';\""
ENV JENKINS_OPTS             ' -Djava.awt.headless=true'
ENV JENKINS_SLAVE_AGENT_PORT '50000'
ENV JENKINS_SECRETS_HOME     '/usr/share/jenkins/ref/secrets'
ENV REF                      '/usr/share/jenkins/ref/plugins'
ENV SCRIPT_APPROVAL_DIR      '/usr/share/jenkins/ref/approval.d'
ENV CONFIG_DIR               '/usr/share/jenkins/ref/config.d'
ENV SHARED_LIBS              '/usr/share/jenkins/ref/libs'

VOLUME ${JENKINS_SECRETS_HOME}

USER root

RUN mkdir -p $SHARED_LIBS

ADD https://raw.githubusercontent.com/agilestacks/jenkins/master/plugins/plugins.txt  ${REF}/plugins.txt
ADD https://raw.githubusercontent.com/agilestacks/jenkins/master/plugins/extras.txt   ${REF}/extras.txt

# COPY init.groovy.d/*.groovy    /usr/share/jenkins/ref/init.groovy.d/
COPY etc/disable-wizard        /usr/share/jenkins/ref/jenkins.install.InstallUtil.lastExecVersion
COPY etc/config.txt            ${CONFIG_DIR}/example.txt
COPY script-approval.txt       ${SCRIPT_APPROVAL_DIR}/initial.txt
COPY etc/slave-to-master       ${JENKINS_SECRETS_HOME}/slave-to-master-security-kill-switch
COPY etc/insecure-robot.secret ${JENKINS_SECRETS_HOME}/robot
# COPY plugins/*.hpi            /usr/share/jenkins/ref/plugins/

RUN chown -R jenkins:jenkins  ${REF} && \
    chown -R jenkins:jenkins  /usr/share/jenkins/ref

VOLUME /usr/share/secrets

EXPOSE 8080
EXPOSE 50000

USER jenkins

WORKDIR /var/jenkins_home

RUN install-plugins.sh $(cat ${REF}/*.txt | xargs)
