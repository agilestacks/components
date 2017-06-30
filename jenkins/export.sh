#!/bin/sh -e

echo "Exporting Jenkins configuration"
cp -Rnv /usr/share/jenkins/ref/plugins/       /jenkins_plugins || true
cp -Rnv /usr/share/jenkins/ref/init.groovy.d/ /jenkins_groovy || true
cp -Rnv /usr/share/jenkins/ref/approval.d/    /jenkins_approval || true
