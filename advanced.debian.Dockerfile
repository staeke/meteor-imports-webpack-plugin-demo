##################################
##### COMMON BASE MACHINE FOR ALL
##### used by both runner and builders
##################################
FROM debian AS miwp-base
RUN apt-get -y update && apt-get -y upgrade
# Packages used by all
RUN apt-get -y install curl
RUN useradd -mu 1001 meteor
WORKDIR /home/meteor

##################################
##### BASE BUILDER WITH PACKAGES
##### used by both client and server builders
##################################
FROM miwp-base AS miwp-builder-base
# Install dev packages. This depends on what npm modules you need. You can be more restrictive here if you care much
# about docker size, and temporarily install the packages before "npm install" and remove them after. Note that you
# need to switch user to root then and run commands with "su" or similar. So - simple for now
RUN apt-get -y install g++ make python git

USER meteor

# Install meteor. NOTE: important with ARG *after* FROM here
ARG METEOR_VERSION=1.7.0.5
RUN curl https://install.meteor.com/?release=${METEOR_VERSION} | sh
ENV PATH="/home/meteor/.meteor:${PATH}"

# Install meteor node_modules
COPY --chown=meteor meteor-app/package*.json meteor-app/
RUN cd meteor-app && \
    meteor npm install --production

# Build an "empty" package-only version of the app
# This includes rewriting package.json to remove any entries for main modules server/client
COPY --chown=meteor meteor-app/packages meteor-app/packages/
COPY --chown=meteor meteor-app/.meteor meteor-app/.meteor/
RUN cd meteor-app && \
    cp package.json package.app.json && \
    meteor node -e "let p = require('./package.json'); delete p.meteor; fs.writeFileSync('package.json', JSON.stringify(p, null, 4, 'utf8'))" && \
    meteor build --debug --directory ../build/pkg-only && \
    rm package.json && \
    mv package.app.json package.json

## We need some build tools for building some npm packaes (i.e. fibers). Install those temporarily, and as root
USER root
RUN apt-get install -y
USER meteor
RUN cd build/pkg-only/bundle/programs/server && \
    meteor npm install --production


###############################
###### SERVER BUILDER (meteor)
###############################
FROM miwp-builder-base AS miwp-builder-server

# Add all files necessary for server.
# Build server app
# We remove all npm packages to enable better cache layering for the runner (packages will come from base)
COPY --chown=meteor /meteor-app/imports/both/ ./meteor-app/imports/both/
COPY --chown=meteor /meteor-app/server/ ./meteor-app/server/
COPY --chown=meteor /meteor-app/public/ ./meteor-app/public/
RUN cd meteor-app && \
    meteor node -e "let p = require('./package.json'); if (p.meteor) { delete p.meteor.mainModule.client; delete p.meteor.testModule} fs.writeFileSync('package.json', JSON.stringify(p, null, 4, 'utf8'))" && \
    meteor build --directory --server-only ../build/app && \
    rm -rf ../build/app/bundle/programs/server/npm/node_modules

###############################
###### CLIENT BUILDER (webpack)
###############################
FROM miwp-builder-base AS miwp-builder-client
ARG ASSET_PATH=/wp/

# Install build time node_modules (such as webpack)
COPY --chown=meteor package*.json ./
RUN meteor npm install

COPY --chown=meteor /wp-meteor-client/ ./wp-meteor-client/
COPY --chown=meteor /meteor-app/imports/ ./meteor-app/imports/
COPY --chown=meteor /meteor-app/public/ ./meteor-app/public/
COPY --chown=meteor /meteor-app/client/ ./meteor-app/client/
COPY --chown=meteor /advanced.webpack.config.js ./
RUN export METEOR_IMPORTS_AUTOUPDATE=1 && \
    export NODE_ENV=production && \
    export ASSET_PATH=$ASSET_PATH && \
    export METEOR_BUILD_DIR=/home/meteor/build/pkg-only && \
    meteor npx webpack --config ./advanced.webpack.config.js


##############################
##### RUNNER
##############################
FROM miwp-base
ARG NODE_VERSION=8.9.4
# Match with serve_wp_bundle.js
ARG ASSET_PATH=/wp/

USER meteor

# Install node (installs node@$NODE_VERSION)
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.10/install.sh | bash
ENV PATH="/home/meteor/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

WORKDIR /home/meteor/app
EXPOSE 3000
# Copy built packages
COPY --chown=meteor --from=miwp-builder-base /home/meteor/build/pkg-only/bundle ./
# Copy our built server and client
COPY --chown=meteor --from=miwp-builder-server /home/meteor/build/app/bundle ./
COPY --chown=meteor --from=miwp-builder-client /home/meteor/build/client/ ./programs/web.browser/app/wp
ENTRYPOINT export AUTOUPDATE_VERSION=$(cat ./programs/web.browser/app/wp/autoupdate_version) && \
    export NODE_ENV=production && \
    export SERVE_WP_BUNDLE=1 && \
    export ASSET_PATH=$ASSET_PATH && \
    export PORT=3000 && \
    node main.js
