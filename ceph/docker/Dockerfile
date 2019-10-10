FROM alpine:3.10
LABEL maintainer="Reinis Streics <reinis@agilestacks.com>"

ENV USER             "root"
ENV UID              "0"
ENV GID              "0"

RUN \
    apk update && apk upgrade && \
    apk add --no-cache \
    bash \
    vim \
    util-linux \
    sgdisk \
    device-mapper \
    jq && \
    rm -rf /var/cache/apk/* /tmp/*
