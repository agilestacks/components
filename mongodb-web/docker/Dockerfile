
# Source
# See https://github.com/mrvautin/adminMongo for details
FROM node:8.9 as source
ARG VERSION=0.0.23
MAINTAINER Artem Kudla <artem@agilestacks.com>

ENV NODE_ENV production

WORKDIR /source

RUN npm pack admin-mongo@$VERSION && \
    tar zxf admin-mongo-$VERSION.tgz && \
    cd package && \
    npm i

# Run
FROM node:8.9
MAINTAINER Artem Kudla <artem@agilestacks.com>

ARG VERSION=0.0.23

WORKDIR /mongodb-dashboard

COPY --from=source /source/package /mongodb-dashboard

ENV NODE_ENV production

# The IP address adminMongo will listen on
ENV HOST 0.0.0.0

# The Port adminMongo will listen on
ENV PORT 80

# An application level password to add simply authentication
ENV PASSWORD ""

# The locale is automatically set to the detected locale of Nodejs.
# If there is not a translation, adminMongo will default to English.
# This setting overrides the default/detected value
ENV LOCALE en

# Setting a context of "dbApp" is like changing the base URL of the app
# and will mean the app will listen on http://10.0.0.1:4321/dbApp.
# Ommiting a context will mean the application will listen on root. Eg: http://10.0.0.1:4321
# This setting can be useful when running adminMongo behind Nginx etc.
ENV CONTEXT ""

# Whether to run monitoring at regular intervals. Defaults to true or on
ENV MONITORING off


# The name of the connection to create on boot
ENV CONN_NAME ""

# The username for the database connection
ENV DB_USERNAME ""

# The password for the database user
ENV DB_PASSWORD ""

# The host IP address or DNS name without the port!
ENV DB_HOST ""

# The port of the mongoDB database, if not provided the default 27017 will be used
ENV DB_PORT ""

# The name of the database
ENV DB_NAME ""

CMD npm start