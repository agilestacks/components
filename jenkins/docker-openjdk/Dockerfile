FROM openjdk:8-jdk-slim
MAINTAINER Antons Kranga <anton@agilestacks.com>

RUN apt-get update && \
    apt-get install -yqq libgconf-2-4 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* 
