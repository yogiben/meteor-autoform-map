AutoForm.addInputType 'map',
	template: 'afMap'
	valueOut: ->
		node = $(@context)
		node.find('.js-lat').val() + ',' + node.find('.js-lng').val()
	contextAdjust: (ctx) ->
		ctx

Template.afMap.rendered = ->
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
			mapTypeId: google.maps.MapTypeId.SATELLITE
		
		@data.map = new google.maps.Map @find('.js-map'), mapOptions

		if @data.value
			location = @data.value.split ','
			location = new google.maps.LatLng parseFloat(location[0]), parseFloat(location[1])
			@data.map.setCenter location
			@data.setMarker @data.map, location
		else
			# TODO: handle default lat/lng
			@data.map.setCenter new google.maps.LatLng -34.397, 150.644

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