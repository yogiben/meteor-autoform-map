Autoform map
============

Edit location coordinates with autoForm.

###Setup###
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
			afFieldInput:
				type: 'map'
				# options

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

Coordinates will be saved as string in format `latititude,longitude`.

###Options###

*mapType* type of google map. Possible values: `'roadmap' 'satellite' 'hybrid' 'terrain'`

*defaultLat* default latitude
*defaultLng* default longitude