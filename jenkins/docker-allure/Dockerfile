### Checkout
FROM alpine/git:latest as scm
MAINTAINER Antons Kranga <anton@agilestacks.com>
ARG GITHUB_TOKEN=set-me-please
WORKDIR /workspace
RUN git init && \
    git remote add -f origin https://github.com/akranga/allure2.git && \
    git pull --depth=1 origin Fix_#769

### Compile
FROM openjdk:8-jdk as jdk

WORKDIR /workspace
COPY --from=scm /workspace .

RUN ./gradlew assemble -x test

RUN mkdir -p /opt && \
    unzip ./allure-commandline/build/distributions/allure-2.3-SNAPSHOT.zip -d /opt

### Install
FROM java:8-alpine

ENV ALLURE_HOME /opt/allure
ENV PATH=${ALLURE_HOME}/bin:${PATH}

RUN mkdir -p /allure/results && \
    mkdir -p /allure/report  && \
    mkdir -p /allure/config  && \
    mkdir -p /opt

COPY --from=jdk /opt/allure-2.3-SNAPSHOT /opt/allure

RUN ln -s ${ALLURE_HOME}/bin/allure /bin/allure && \
    chmod +x /bin/*

ENTRYPOINT allure
