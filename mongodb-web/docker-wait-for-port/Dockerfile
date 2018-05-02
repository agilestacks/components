FROM alpine:latest
RUN apk add --update netcat-openbsd bc && rm -rf /var/cache/apk/*
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

ENV WAIT_TIMEOUT "300"

# The host IP address or DNS name without the port!
ENV HOST ""

# The port
ENV PORT ""

ENV PORT_NAME ""

ENV CHECK_INTERVAL ""
