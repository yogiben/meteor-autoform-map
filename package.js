Package.describe({
  name: 'roshdy:autoform-map',
  summary: 'Edit location coordinates with autoForm',
  version: '2.1.6',
  git: 'https://github.com/Roshdy/meteor-autoform-map'
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@1.4');

  api.use([
  	'coffeescript',
  	'templating',
    'reactive-var',
  	'aldeed:autoform@5.8.1'
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
