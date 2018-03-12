### Checkout
FROM alpine/git:latest as scm
MAINTAINER Antons Kranga <anton@agilestacks.com>
ARG GITHUB_TOKEN=set-me-please
WORKDIR /workspace
RUN git init && \
    git remote add -f origin https://github.com/capitalone/Hygieia.git && \
    git config core.sparseCheckout true && \
    # echo "cli/src" >> .git/info/sparse-checkout && \
    # echo "cli/Makefile" >> .git/info/sparse-checkout && \
    # echo "cli/nodocker.make" >> .git/info/sparse-checkout && \
    git pull --depth=1 origin master

### Build
FROM openjdk:8-jdk-alpine as builder
MAINTAINER Antons Kranga <anton@agilestacks.com>


# RUN apk update && apk upgrade && \
#     apk add --no-cache git
WORKDIR /workspace
COPY --from=scm /workspace /workspace
RUN /workspace/mvnw \
        -pl '!UI,!UI-tests' \
        -Dmaven.test.skip=true  \
        clean install package

### Run
FROM openjdk:8-alpine
MAINTAINER Antons Kranga <anton@agilestacks.com>

ARG TINI_VERSION="0.16.1"

ADD https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-amd64 /usr/local/bin/tini
RUN chmod +x /usr/local/bin/*

COPY --from=builder /workspace /hygieia
COPY --from=builder /workspace/db /hygieia/db
COPY --from=builder /workspace/api/target/*.jar /hygieia/lib
COPY --from=builder /workspace/api-audit/target/*.jar /hygieia/lib
COPY --from=builder /workspace/collectors/build/jenkins-codequality/target/*.jar /hygieia/lib
COPY --from=builder /workspace/collectors/build/jenkins-cucumber/target/*.ja /hygieia/collectors
COPY --from=builder /workspace/ecollectors/build/jenkins/target/*.jar /hygieia/collectors
COPY --from=builder /workspace/collectors/build/sonar/target/*.jar /hygieia/collectors
COPY --from=builder /workspace/collectors/cloud/aws/target/*.jar /hygieia/collectors
COPY --from=builder /workspace/collectors/deploy/udeploy/target/*.jar /hygieia/collectors
COPY --from=builder /workspace/collectors/deploy/xldeploy/target/*.jar . /hygieia/collectors
COPY --from=builder /workspace/collectors/build/jenkins-codequality/target/jenkins-codequality-*.jar . /app/collectors
COPY --from=builder /workspace/collectors/feature/gitlab/target/*.jar . /hygieia/collectors
COPY --from=builder /workspace/collectors/feature/versionone/target/*.jar . /hygieia/collectors
COPY --from=builder /workspace/collectors/library-policy/nexus-iq-collector/target/*.jar . /hygieia/collectors
COPY --from=builder /workspace/collectors/misc/chat-opsr/target/*.jar . /hygieia/collectors
COPY --from=builder /workspace/collectors/scm/github/target/*.jar . /hygieia/collectors
COPY --from=builder /workspace/collectors/scm/github-graphql/target/*.jar . /hygieia/collectors
COPY --from=builder /workspace/collectors/scm/gitlab/target/*.jar . /hygieia/collectors
COPY --from=builder /workspace/core/target/*.jar . /hygieia/collectors
COPY --from=builder /workspace/hygieia-jenkins-plugin/target/hygieia-publisher.hpi . /hygieia/jenkins
COPY --from=builder /workspce/api/docker/api-properties-builder.sh /hygieia

VOLUME ["/hygieia/logs"]

EXPOSE 8080

WORKDIR /hygieia
