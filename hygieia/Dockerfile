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
RUN mkdir -p dist && \
    find /workspace -name target -exec echo cp -f {}/*.jar dist \; | sh -

### Run
FROM openjdk:8-alpine
MAINTAINER Antons Kranga <anton@agilestacks.com>

ARG TINI_VERSION="0.16.1"

ENV PATH "$PATH:/hygieia/bin"

ADD https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-amd64 /usr/local/bin/tini
RUN chmod +x /usr/local/bin/* && \
    mkdir -p /hygieia/conf

# COPY --from=builder /workspace /hygieia
COPY --from=builder /workspace/db /hygieia/db
COPY --from=builder /workspace/dist /hygieia/lib
COPY --from=builder /workspace/api/docker/api-properties-builder.sh /hygieia/bin

VOLUME ["/hygieia/logs"]

EXPOSE 8080

WORKDIR /hygieia
