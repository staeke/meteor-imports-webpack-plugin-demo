function requireAll(r) {
    r.keys().forEach(r);
}

requireAll(require.context('../meteor-app/client', true, /\.css$/));
require('../meteor-app/imports/client/start');

if (module.hot)
    module.hot.accept();
