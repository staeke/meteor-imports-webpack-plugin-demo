const path = require('path');
const MeteorImportsPlugin = require('meteor-imports-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
    entry: './wp-meteor-client/entry.js',
    resolve: {
        // When testing this app with "npm" link, run node with --preserve-symlinks, and uncomment:
        // symlinks: false,
        extensions: ['.jsx', '.js']
    },
    module: {
        rules: [
            {
                test: /\.(js|jsx)$/,
                exclude: [/node_modules/, /\.meteor/],
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: ['@babel/preset-env', '@babel/preset-react']
                    }
                },
            },
            {
                test: /\.css$/,
                use: ['style-loader', 'css-loader'],
            },
        ]
    },
    devServer: {
        /**
         * We run the dev-server so that it fallbacks to serving stuff from the meteor app's public directory
         */
        contentBase: path.join(__dirname, 'meteor-app/public')
    },
    plugins: [
        new MeteorImportsPlugin({
            meteorFolder: 'meteor-app',
            exclude: {
                /**
                 * The following is an advanced concept. We're using the Meteor package bootstrap, which depends
                 * on Meteor package "jQuery". However, we also want to use jQuery from js (via import/require and
                 * npm). Thus, for demonstration purposes, we've overridden the Meteor "jQuery" package, by replacing
                 * it with an inline object requiring the npm version. If you want to do something similar, be sure to
                 * inspect the Meteor package's export variable via Package.foo, to see what it looks like.
                 */
                jquery: '{jQuery: require("jquery")}'
            }
        }),
        new HtmlWebpackPlugin({
            template: './wp-meteor-client/index.html'
        }),
    ]
};
