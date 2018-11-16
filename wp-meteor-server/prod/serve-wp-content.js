import {Meteor} from 'meteor/meteor';
import {WebApp} from 'meteor/webapp';
import * as path from 'path';

function isEnvTrue(envVar) {
    return envVar && envVar !== 'false' && envVar !== '0';
}

if (isEnvTrue(process.env.SERVE_WP_BUNDLE)) {

    function setStaticCacheHeader(res, isPublic = true) {
        res.setHeader('cache-control', (isPublic ? 'public' : 'private') + ', max-age=31536000' /*1 year*/);
        // We must remove the ETag header set by meteor to avoid 304s, through a hack
        const origSetHeader = res.setHeader;
        res.setHeader = function(header) {
            if (!header || header.toLowerCase() !== 'etag')
                origSetHeader.apply(res, arguments);
        };
    }

    console.log('Setting up direct serving of webpack client bundle');
    WebApp.rawConnectHandlers.use((req, res, next) => {
        const ext = path.extname(req.url);
        if (req.method === 'GET' && !ext) {
            req.url = '/wp-build/index.html';
        } else if (req.url.startsWith('wp-build')) {
            if (ext === '.map' && !Meteor.isDevelopment) {
                const hasSourceMapAccess = false; // Change as needed
                if (!hasSourceMapAccess) {
                    res.statusCode = 403;
                    res.end('Access denied');
                    return;
                }
            } else if (ext.match(/^(js|woff|jpg|jpeg|png|svg|gif|woff2|eot)$/)) {
                setStaticCacheHeader(res);
            }
        }

        next();
    }
}
