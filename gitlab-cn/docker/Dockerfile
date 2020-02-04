FROM python:3.4.8-alpine

RUN apk update && \
    apk add --update --no-cache g++ gcc libxslt-dev && \
    rm -rf /var/cache/apk/* /tmp/requirements.txt

ADD requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt

ADD scripts/gitlab_create_token.py /usr/sbin/gitlab_create_token.py


CMD /usr/sbin/gitlab_create_token.py
