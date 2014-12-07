defaults =
	mapType: 'roadmap',
	defaultLat: -34.397
	defaultLng: 150.644
	geolocation: false

AutoForm.addInputType 'map',
	template: 'afMap'
	valueOut: ->
		node = $(@context)
		node.find('.js-lat').val() + ',' + node.find('.js-lng').val()
	contextAdjust: (ctx) ->
		ctx

Template.afMap.rendered = ->
	@data.options = _.extend {}, defaults, @data.atts

	@data.marker = undefined
	@data.setMarker = (map, location) =>
		@$('.js-lat').val(location.lat())
		@$('.js-lng').val(location.lng())

		if @data.marker then @data.marker.setMap null
		@data.marker = new google.maps.Marker
			position: location
			map: map

	GoogleMaps.init {}, () =>
		mapOptions =
			zoom: 13
			mapTypeId: google.maps.MapTypeId[@data.options.mapType]
		
		@data.map = new google.maps.Map @find('.js-map'), mapOptions

		if @data.value
			location = @data.value.split ','
			location = new google.maps.LatLng parseFloat(location[0]), parseFloat(location[1])
			@data.setMarker @data.map, location
			@data.map.setCenter location
		else
			@data.map.setCenter new google.maps.LatLng @data.options.defaultLat, @data.options.defaultLng

		google.maps.event.addListener @data.map, 'click', (e) =>
			@data.setMarker @data.map, e.latLng

Template.afMap.helpers
	schemaKey: ->
		@atts['data-schema-key']
	width: ->
		if typeof @atts.width == 'string'
			@atts.width
		else if typeof @atts.width == 'number'
			@atts.width + 'px'
		else
			'200px'
	height: ->
		if typeof @atts.height == 'string'
			@atts.height
		else if typeof @atts.height == 'number'
			@atts.height + 'px'
		else
			'200px'

Template.afMap.events
	'click .js-locate': (e) ->
		e.preventDefault()
		navigator.geolocation?.getCurrentPosition (position) =>
			location = new google.maps.LatLng position.coords.latitude, position.coords.longitude
			@setMarker @map, location