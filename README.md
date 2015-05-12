Autoform map
============

Edit location coordinates with autoForm.

### Setup ###
1) Install `meteor add yogiben:autoform-map`

2) Define your schema and set the `autoform` property like in the example below
```
Schemas = {}

@Cities = new Meteor.Collection('cities');

Schemas.Cities = new SimpleSchema
	name:
		type:String
		max: 60
		
	location:
		type: String
		autoform:
			type: 'map'
			afFieldInput:
      				geolocation: true
      				searchBox: true
      				autolocate: true

Cities.attachSchema(Schemas.Cities)
```

3) Generate the form with `{{> quickform}}` or `{{#autoform}}`

e.g.
```
{{> quickForm collection="Cities" type="insert"}}
```

or

```
{{#autoForm collection="Cities" type="insert"}}
    {{> afQuickField name="name"}}
    {{> afQuickField name="location"}}
    <button type="submit" class="btn btn-primary">Insert</button>
{{/autoForm}}
```

Coordinates will be saved as string in format `latititude,longitude`. Alternatively it can be an object. See schema below:

```
Schemas.Cities = new SimpleSchema
	location:
		type: Object
		autoform:
			type: 'map'
			afFieldInput:
				# options
	'location.lat':
		type: String
	'location.lng':
		type: String
```

Or if you want to save lat and lng as a number:

```
Schemas.Cities = new SimpleSchema
	location:
		type: Object
		autoform:
			type: 'map'
			afFieldInput:
				# options
	'location.lat':
		type: Number
		decimal: true
	'location.lng':
		type: Number
		decimal: true
```

### Options ###

*mapType* type of google map. Possible values: `'roadmap' 'satellite' 'hybrid' 'terrain'`

*width* *height* valid css values for width and height attributes of map. Default width is set to `'100%'` and height is `'200px'`

*defaultLat* default latitude
*defaultLng* default longitude

*geolocation* enables or disables geolocation feature. Defaults to `false`

*searchBox* enables or disables search box. Defaults to `false`

*zoom* zoom of the map. Defaults to `13`

*autolocate* if set to `true` will automatically ask for user's location. Defaults to `false`

*googleMap* google maps specific [options](https://developers.google.com/maps/documentation/javascript/reference#MapOptions).

*rendered* function called when map is rendered. [google.maps.Map](https://developers.google.com/maps/documentation/javascript/reference#Map) will be passed as an argument.

*reverse* if set to `true` lat.lng will be reversed to lng.lat. Works only with strings.

```
	location:
		type: String
		autoform:
			afFieldInput:
				type: 'map'
				mapType: 'terrain'
				zoom: 8
				geolocation: true
```
