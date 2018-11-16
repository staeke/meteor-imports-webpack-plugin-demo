import * as path from 'path';
import {Meteor} from 'meteor/meteor';
import {WebApp} from 'meteor/webapp';

/**
 * This code is meant to bridge Meteor -> Webpack client file serving in production (or debugging production like
 * conditions). We put the webpack built files under the app's equivalent to /public + $ASSET_PATH and pass environment
 * variable SERVE_WP_BUNDLE=1 to kick this off
 *
 * Also consider setting any static cache headers
 */


// Match the following with webpack config

// This regex matches all static files with a hashed extension. Corresponds to webpack's file loader options
const REGEX_HASHED_ASSET = /[a-z0-9]{20,32}.(?:js|css|was|jpg|jpeg|gif|png|svg|woff|woff2|eot|mp4|mp3|wav|aiff|mpg|mpeg)/;
// The webpack (WP) output asset path directory.
const ASSET_PATH = process.env.ASSET_PATH || '/';


function setStaticCacheHeader(res) {
    res.setHeader('cache-control', 'max-age=31536000' /*1 year*/);
    // We must remove the ETag header set by meteor to avoid 304s, through a hack
    const origSetHeader = res.setHeader;
    res.setHeader = function(header) {
        if (!header || header.toLowerCase() !== 'etag')
            origSetHeader.apply(res, arguments);
    };
}

// Allow other handlers to set things up so that this is last
// console.log('Process env', process.env);
if (process.env.SERVE_WP_BUNDLE) {
    Meteor.startup(() => {
        WebApp.rawConnectHandlers.use((req, res, next) => {
            const ext = path.extname(req.url);
            if (req.method === 'GET' && !ext) {
                // If your main file is called something other than "index.html" - change this file
                req.url = ASSET_PATH + 'index.html';
            } else if (ext === '.map') {
                // Consider access restrictions if you want
            } else if (ext.startsWith(ASSET_PATH) && req.url.match(REGEX_HASHED_ASSET)) {
                setStaticCacheHeader(res);
            }
            next();
        });
    });
}
