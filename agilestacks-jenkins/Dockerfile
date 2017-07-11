FROM docker.io/agilestacks/jenkins:2.46.1-3

ENV  JENKINS_URL        jenkins.app.anton7.kubernetes.delivery
ENV  ADMIN_EMAIL        dev@agilestacks.com
ENV  GITHUB_DEPLOY_KEY  75e43dd2d24dd39b6c205a600b47d642daed4d04

COPY init.groovy.d/*.groovy /usr/share/jenkins/ref/init.groovy.d/

# COPY secrets/github.txt /usr/share/jenkins/ref/agilestacks/github-key.txt