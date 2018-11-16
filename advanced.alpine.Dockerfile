##################################
##### BASE BUILDER WITH PACKAGES
##################################
#important with ARG *before* FROM
ARG METEOR_VERSION=1.7.0.5
FROM staeke/meteor-alpine:$METEOR_VERSION AS miwp-builder-base
USER meteor
# NOTE: WORKDIR is /home/meteor

# Install meteor node_modules
COPY --chown=meteor meteor-app/package*.json meteor-app/
RUN cd meteor-app && \
    npm install --production

### Setup the different build configs through symlinks
RUN mkdir build && \
    mkdir app-pkg-only && \
    cd app-pkg-only && \
    ln -s ../meteor-app/.meteor && \
    ln -s ../meteor-app/packages && \
    ln -s ../meteor-app/node_modules

# Install build time node_modules
COPY --chown=meteor package*.json ./
RUN npm install

# Build app-pkg-only
COPY --chown=meteor meteor-app/packages meteor-app/packages/
COPY --chown=meteor meteor-app/.meteor meteor-app/.meteor/
RUN cd app-pkg-only && \
    meteor build --debug --directory ../build/pkg-only

# We need some build tools for building some npm packaes (i.e. fibers). Install those temporarily, and as root
USER root
RUN apk add --no-cache g++ make python && \
    cd build/pkg-only/bundle/programs/server && \
    su meteor -c 'yarn install --production' && \
    apk del g++ make python
USER meteor


##############################
##### SERVER BUILDER (meteor)
##############################
FROM miwp-builder-base AS miwp-builder-server

# Add all files necessary for server. By using a more split directory structure (client/server) this can be simplified
# Note that we provide dummies for client and tests
COPY --chown=meteor /meteor-app/imports/both/ ./meteor-app/imports/both/
COPY --chown=meteor /meteor-app/server/ ./meteor-app/server/
COPY --chown=meteor /meteor-app/public/ ./meteor-app/public/
RUN cd meteor-app && \
    mkdir client && touch client/main.js && \
    mkdir tests && touch tests/main.js

# Build server app
# We remove all npm packages to enable better cache layering for the runner (packages will come from base)
RUN cd meteor-app && \
    meteor build --directory --server-only ../build/app && \
    rm -rf ../build/app/bundle/programs/server/npm/node_modules


##############################
##### CLIENT BUILDER (webpack)
##############################
FROM miwp-builder-base AS miwp-builder-client
COPY --chown=meteor /wp-meteor-client/ ./wp-meteor-client/
COPY --chown=meteor /meteor-app/imports/ ./meteor-app/imports/
COPY --chown=meteor /meteor-app/public/ ./meteor-app/public/
COPY --chown=meteor /meteor-app/client/ ./meteor-app/client/
COPY --chown=meteor /webpack.config.js ./
RUN export METEOR_IMPORTS_AUTOUPDATE=1 && \
    export NODE_ENV=production && \
    export METEOR_BUILD_DIR=/home/meteor/build/pkg-only && \
    yarn webpack --config ./webpack.config.js


#############################
#### RUNNER STAGE
#############################
ARG METEOR_VERSION=1.7.0.5
# Match with serve_wp_bundle.js
ARG ASSET_PATH=wp/
FROM staeke/meteor-node-alpine:$METEOR_VERSION
USER meteor
WORKDIR /home/meteor/app
EXPOSE 3000
# Copy built packages
COPY --chown=meteor --from=miwp-builder-base /home/meteor/build/pkg-only/bundle ./
# Copy our built server and client
COPY --chown=meteor --from=miwp-builder-server /home/meteor/build/app/bundle ./
COPY --chown=meteor --from=miwp-builder-client /home/meteor/build/client/ ./programs/web.browser/app/$ASSET_PATH
ENTRYPOINT export AUTOUPDATE_VERSION=$(cat ./programs/web.browser/app/autoupdate_version) && \
    export NODE_ENV=production && \
    export SERVE_WP_BUNDLE=1 && \
    export PORT=3000 && \
    node main.js
