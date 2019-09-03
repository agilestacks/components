FROM python:3.4.8-alpine

# LABEL Vikas Kumar "vikas@reachvikas.com"

RUN apk update && \
    apk add --update --no-cache g++ gcc libxslt-dev && \
    rm -rf /var/cache/apk/* /tmp/requirements.txt

ADD requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt

ADD scripts/gitlab_create_token.py /usr/sbin/gitlab_create_token.py


ENV TOKEN_NAME=terraform TOKEN_EXPIRE=2020-08-27

CMD /usr/sbin/gitlab_create_token.py ${TOKEN_NAME} ${TOKEN_EXPIRE}
