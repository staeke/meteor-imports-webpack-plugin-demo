const path = require('path');
const MeteorImportsPlugin = require('meteor-imports-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const MiniCssExtractPlugin = require("mini-css-extract-plugin");

const meteorFolderOptions = process.env.METEOR_BUILD_DIR
    ? {meteorProgramsFolder: path.resolve(process.env.METEOR_BUILD_DIR, 'bundle/programs')}
    : {meteorFolder: 'meteor-app'};

module.exports = {
    mode: process.env.NODE_ENV || 'development',
    entry: './wp-meteor-client/entry.js',
    resolve: {
        // When testing this app with "npm" link, run node with --preserve-symlinks, and uncomment:
        // symlinks: false,
        extensions: ['.jsx', '.js', '.css']
    },
    output: {
        path: path.resolve(__dirname, 'build/client'),
        publicPath: process.env.ASSET_PATH || '/',
        filename: '[name].[contenthash].js'
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
                use: [
                    MiniCssExtractPlugin.loader,
                    "css-loader"
                ]
            },
            {
                test: /\.(eot|svg|ttf|woff|woff2)$/,
                loader: 'file-loader',
            },
        ]
    },
    devServer: {
        contentBase: path.join(__dirname, 'meteor-app/public')
    },
    plugins: [
        new MeteorImportsPlugin({
            ...meteorFolderOptions,
            exclude: {
                autoupdate: !process.env.METEOR_IMPORTS_AUTOUPDATE,
                jquery: '{jQuery: require("jquery")}'
            }
        }),
        new HtmlWebpackPlugin({
            template: './wp-meteor-client/index.html'
        }),
        new MiniCssExtractPlugin({
            // Options similar to the same options in webpackOptions.output
            // both options are optional
            filename: "[name].[contenthash].css",
            chunkFilename: "[id].[contenthash].css"
        })
    ]
};
