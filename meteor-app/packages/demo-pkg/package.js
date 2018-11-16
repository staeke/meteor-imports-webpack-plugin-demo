// Information about this package:
Package.describe({
    summary: 'Demo for private package',
    version: '1.0.0',
});

Package.onUse((api) => {
    api.mainModule('demo-pkg.js');
});
