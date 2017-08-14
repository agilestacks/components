FROM java:8-alpine

ARG ALLURE_VERSION=2.3.3
ENV PATH=/opt/allure-${ALLURE_VERSION}/bin:${PATH}

RUN mkdir -p /allure/results && \
    mkdir -p /allure/report  && \
    mkdir -p /allure/config  && \
    mkdir -p /opt

ADD https://dl.bintray.com/qameta/generic/io/qameta/allure/allure/${ALLURE_VERSION}/allure-${ALLURE_VERSION}.zip /tmp/allure.zip

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh make zip openssl && \
    unzip /tmp/allure.zip -d /opt && \
    chmod +x /bin/*

RUN rm /var/cache/apk/* && \
    rm -rf /tmp/*

ENTRYPOINT /opt/allure-${ALLURE_VERSION}/bin/allure