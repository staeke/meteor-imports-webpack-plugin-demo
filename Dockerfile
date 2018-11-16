ARG METEOR_VERSION=1.7.0.5
FROM debian

# Install Meteor
ENV METEOR_ALLOW_SUPERUSER=1
RUN curl https://install.meteor.com/?release=${METEOR_VERSION} | sh

# Build app
COPY /meteor-app/ /home/root/meteor-app/
WORKDIR /home/root/meteor-app
RUN meteor build --directory ../build/app
WORKDIR /home/root/build/bundle

# Install packages
RUN cd programs/server && meteor npm install

# Set up how to run app
EXPOSE 80
ENTRYPOINT export NODE_ENV=production && \
    export PORT=80 && \
    node main.js

