FROM alpine:latest
RUN apk add --update netcat-openbsd bc && rm -rf /var/cache/apk/*
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

ENV WAIT_TIMEOUT "300"

# The host IP address or DNS name without the port!
ENV DB_HOST ""

# The port of the mongoDB database, if not provided the default 27017 will be used
ENV DB_PORT ""
