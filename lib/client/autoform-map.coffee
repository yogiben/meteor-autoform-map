KEY_ENTER = 13

defaults =
	mapType: 'roadmap'
	defaultLat: 1
	defaultLng: 1
	geolocation: false
	searchBox: false
	autolocate: false
	zoom: 13

AutoForm.addInputType 'map',
	template: 'afMap'
	valueOut: ->
		node = $(@context)
		
		lat = node.find('.js-lat').val()
		lng = node.find('.js-lng').val()

		if lat.length > 0 and lng.length > 0
			lat: lat
			lng: lng
	contextAdjust: (ctx) ->
		ctx.loading = new ReactiveVar(false)
		ctx
	valueConverters:
		string: (value) ->
			if @attr('reverse')
				"#{value.lng},#{value.lat}"
			else
				"#{value.lat},#{value.lng}"

Template.afMap.created = ->
	GoogleMaps.load(libraries: 'places')

initTemplateAndGoogleMaps = ->
	@data.options = _.extend {}, defaults, @data.atts

	@data.marker = undefined
	@data.setMarker = (map, location, zoom=0) =>
		@$('.js-lat').val(location.lat())
		@$('.js-lng').val(location.lng())

		if @data.marker then @data.marker.setMap null
		@data.marker = new google.maps.Marker
			position: location
			map: map

		if zoom > 0
			@data.map.setZoom zoom

	mapOptions =
		zoom: 0
		mapTypeId: google.maps.MapTypeId[@data.options.mapType]
		streetViewControl: false

	if @data.atts.googleMap
		_.extend mapOptions, @data.atts.googleMap

	@data.map = new google.maps.Map @find('.js-map'), mapOptions

	if @data.value
		location = if typeof @data.value == 'string' then @data.value.split ',' else [@data.value.lat, @data.value.lng]
		location = new google.maps.LatLng parseFloat(location[0]), parseFloat(location[1])
		@data.setMarker @data.map, location, @data.options.zoom
		@data.map.setCenter location
	else
		@data.map.setCenter new google.maps.LatLng @data.options.defaultLat, @data.options.defaultLng
		@data.map.setZoom @data.options.zoom

	if @data.atts.searchBox
		input = @find('.js-search')

		@data.map.controls[google.maps.ControlPosition.TOP_LEFT].push input
		searchBox = new google.maps.places.SearchBox input

		google.maps.event.addListener searchBox, 'places_changed', =>
			location = searchBox.getPlaces()[0].geometry.location
			@data.setMarker @data.map, location
			@data.map.setCenter location

		$(input).removeClass('af-map-search-box-hidden')

	if @data.atts.autolocate and navigator.geolocation and not @data.value
		navigator.geolocation.getCurrentPosition (position) =>
			location = new google.maps.LatLng position.coords.latitude, position.coords.longitude
			@data.setMarker @data.map, location, @data.options.zoom
			@data.map.setCenter location

	if typeof @data.atts.rendered == 'function'
		@data.atts.rendered @data.map

	google.maps.event.addListener @data.map, 'click', (e) =>
		@data.setMarker @data.map, e.latLng

	@$('.js-map').closest('form').on 'reset', =>
		@data.marker and @data.marker.setMap null
		@data.map.setCenter new google.maps.LatLng @data.options.defaultLat, @data.options.defaultLng
		@data.map.setZoom 0

Template.afMap.rendered = ->
	@autorun =>
		GoogleMaps.loaded() and initTemplateAndGoogleMaps.apply this

Template.afMap.helpers
	schemaKey: ->
		@atts['data-schema-key']
	width: ->
		if typeof @atts.width == 'string'
			@atts.width
		else if typeof @atts.width == 'number'
			@atts.width + 'px'
		else
			'100%'
	height: ->
		if typeof @atts.height == 'string'
			@atts.height
		else if typeof @atts.height == 'number'
			@atts.height + 'px'
		else
			'200px'
	loading: ->
		@loading.get()

Template.afMap.events
	'click .js-locate': (e, t) ->
		e.preventDefault()

		unless navigator.geolocation then return false

		@loading.set true
		navigator.geolocation.getCurrentPosition (position) =>
			location = new google.maps.LatLng position.coords.latitude, position.coords.longitude
			@setMarker @map, location, @options.zoom
			@map.setCenter location
			@loading.set false

	'keydown .js-search': (e) ->
		if e.keyCode == KEY_ENTER then e.preventDefault()
