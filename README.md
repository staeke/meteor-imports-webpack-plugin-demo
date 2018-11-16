# Demo project for Meteor Imports Webpack Plugin

## Run our demo
Clone this repo, then

```sh
cd demo
npm i
npm run start
```

**NOTE: The first time, you will get an error, pls run twice (for now)**

Go to http://localhost:4000

#### Separate tabs/windows
If you prefer to run the webpack client build, and meteor server in separate tabs/windows, run these commands in two different sessions

```sh
npx wp-dev-server
```

```sh
npx wp-meteor-server
```

### How does this work?
First, there's a very normal meteor app under `meteor-app`. It works just like any meteor app. This one uses React with the `blaze` package removed and the `static-html` package added (Blaze isn't directly supported with this plugin). It also has the `twbs:bootstrap` package installed for demo purposes. Note how it uses the `import` directory heavily.

The directory `wp-meteor-server` is a directory that contains symlinks in to the other project, with the exception of client files. Thus it functions just like any meteor app, except it doesn't "have" any client files. We will run meteor from within this directory, and provide the client files through other means - a webpack build.

The directory `wp-meteor-client/entry.js` contains the startup code for the client application. And `webpack.config.js` is the webpack configuration to get it all going. Thus the client starts in `entry.js`, loads some css, and then kicks off the client application.


### Common gotchas

#### Meteor npm wrapper libraries
With the webpack build, we generally want 3rd party libraries to be included by npm. Normally this would work fine with thin Meteor wrapper libraries. But, if the libraries have the code bundled, and/or depends on global variables being set (not normal Meteor package dependencies). In this example project, we **have** such an example. The `twbs:bootstrap` library depends on Meteor package `jquery` and this library bundles jQuery. And the thin wrapper depends on global `window.jQuery` being set. This is bad and we want to provide our own version of `jQuery` via npm. Thus, we pass this to `MeteorImportsWebpackPlugin` in `webpack.config.js`:

```js
exclude: {
    jquery: '{jQuery: require("jquery")}'
}
```

It tells the plugin that `jquery` should instead be set to an object with one variable `jQuery` that is set to the npm library `jquery`.

#### Different node_modules
In this project's setup there's different `node_modules` directories. One in the root, used for the webpack client build, and one for the meteor app. You **can** symlink the root so that they all share the same `node_modules`. If you do, you might get a longer meteor build time due to more files being copied by meteor's build command. And you might get problems with resolving different version dependencies of libraries. On the other hand you may make life simpler, as there are fewer differences to consider overall.

#### Running `meteor` in different places
Note that by running `meteor` in `wp-meteor-server` and `meteor-app` you essentially create the meteor files used for building the client files. And - by running the commands in different directories you will get **different** files. If you run meteor in the `meteor-app` directory, Meteor will also consider imported npm libraries from client files and bundle them as well. If you've done this, and then run the webpack client build, this build might pick up npm libraries twice. Thus, you might get into problems! If you want to run meteor in both directories (but at different times), consider **not** symlinking the `wp-meteor-server/.meteor` directory to `meteor-app/.meteor`. Instead keep a copy, or link only `.meteor/packages`.

## Deployment via Docker
Note that for this to work, you need to have Docker installed https://www.docker.com/get-started

#### Simple
**NOTE: Currently not working**

There is a very simple docker deployment, that should be relatively easy to understand running `Dockerfile`. Run

```bash
docker build . -t miwp-demo
```

Once that finished, you can run it via

```
docker run -it -p 3000:80 --env-file docker.env miwp-demo
```

...and your server will be accessible on port 3000 (change it in the command above if you like).

#### More advanced Docker setups
The simple scenario above has some downsides, that the advanced setups try to fix:

* it takes a long time to run
* they are run as `root` within the Docker container (not the recommended policy by Docker and you'll get Meteor warnings)
* the final image produced is bigger than it has to
* autoupdate/hot code push/reload functionality of Meteor is disabled
* there isn't any HTTP headers sent for cacheability

To the rescue, the more advanced setup, which is based on Docker multi-stage builds https://docs.docker.com/develop/develop-images/multistage-build/. There is one Dockerfile for Debian and one for Alpine. The Debian is more inline with standard Meteor support, and thus more robust. The Alpine end result will, however, be slightly smaller. Checkout:

* `advanced.webpack.config.js`
* `advanced.debian.Dockerfile` or `advanced.alpine.Dockerfile`

Then, to build (Debian), run:

```
docker build -f advanced.debian.Dockerfile . -t miwp-demo
```

To run that image, run the following (NOTE port 3000 as we're not running as `root` and can't use low numbered ports)

```
docker run -it -p 3000:3000 --env-file docker.env miwp-demo
```

#### Versions of Node and Meteor
The docker build scripts take two optional build args. If you're using bash, you can get them like this:

```
METEOR_VERSION=$(cd meteor-app; meteor --version | cut -d " " -f 2)
NODE_VERSION=$(cd meteor-app; meteor node --version)
docker --build-arg METEOR_VERSION=$METEOR_VERSION --build-arg NODE_VERSION=$NODE_VERSION build -f ([...rest of command])
```
