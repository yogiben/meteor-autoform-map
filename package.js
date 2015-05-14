Package.describe({
  name: 'yogiben:autoform-map',
  summary: 'Edit location coordinates with autoForm',
  version: '0.1.1',
  git: 'https://github.com/yogiben/meteor-autoform-map'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');

  api.use([
  	'coffeescript',
  	'templating',
    'reactive-var',
  	'aldeed:autoform@4.2.2 || 5.1.2'
  ], 'client');

  api.imply([
    'dburles:google-maps@1.0.9'
  ], 'client');

  api.addFiles([
  	'lib/client/autoform-map.html',
    'lib/client/autoform-map.css',
  	'lib/client/autoform-map.coffee'
  ], 'client');
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('yogiben:autoform-map');
  api.addFiles('autoform-map-tests.js');
});
