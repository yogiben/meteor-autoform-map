Package.describe({
  name: 'yogiben:autoform-map',
  summary: 'Edit location coordinates with autoForm',
  version: '0.2.0',
  git: 'https://github.com/yogiben/meteor-autoform-map'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');

  api.use([
  	'coffeescript',
  	'templating',
    'reactive-var',
  	'aldeed:autoform@5.6.0'
  ], 'client');

  api.imply([
    'dburles:google-maps@1.1.5'
  ], 'client');

  api.addFiles([
  	'lib/client/autoform-map.html',
    'lib/client/autoform-map.css',
  	'lib/client/autoform-map.coffee'
  ], 'client');
});
