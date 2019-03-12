FROM java:8-alpine

ARG ALLURE_VERSION=2.10.0
ENV ALLURE_HOME /opt/allure-${ALLURE_VERSION}
ENV PATH=${ALLURE_HOME}/bin:${PATH}

RUN mkdir -p /allure/results && \
    mkdir -p /allure/report  && \
    mkdir -p /allure/config  && \
    mkdir -p /opt

ADD https://dl.bintray.com/qameta/maven/io/qameta/allure/allure-commandline/${ALLURE_VERSION}/allure-commandline-${ALLURE_VERSION}.zip /tmp/allure.zip

RUN apk update && \
    apk upgrade && \
    apk add --no-cache bash git openssh make zip openssl && \
    unzip /tmp/allure.zip -d /opt && \
    ln -s ${ALLURE_HOME}/bin/allure /bin/allure && \
    chmod +x /bin/*

RUN rm /var/cache/apk/* && \
    rm -rf /tmp/*

ENTRYPOINT allure
