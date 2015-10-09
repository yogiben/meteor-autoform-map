KEY_ENTER = 13

defaults =
	mapType: 'roadmap'
	defaultLat: 1
	defaultLng: 1
	geolocation: false
	searchBox: false
	autolocate: false
	zoom: 1

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
		numberArray: (value) ->
			[value.lng, value.lat]

Template.afMap.created = ->
	@mapReady = new ReactiveVar false
	GoogleMaps.load(libraries: 'places')

	@_stopInterceptValue = false
	@_interceptValue = (ctx) ->
		t = Template.instance()
		if t.mapReady.get() and ctx.value and not t._stopInterceptValue
			location = if typeof ctx.value == 'string' then ctx.value.split ',' else if ctx.value.hasOwnProperty 'lat' then [ctx.value.lat, ctx.value.lng] else [ctx.value[1], ctx.value[0]]
			location = new google.maps.LatLng parseFloat(location[0]), parseFloat(location[1])
			t.setMarker t.map, location, t.options.zoom
			t.map.setCenter location
			t._stopInterceptValue = true

initTemplateAndGoogleMaps = ->
	@options = _.extend {}, defaults, @data.atts

	@data.marker = undefined
	@setMarker = (map, location, zoom=0) =>
		@$('.js-lat').val(location.lat())
		@$('.js-lng').val(location.lng())

		if @data.marker then @data.marker.setMap null
		@data.marker = new google.maps.Marker
			position: location
			map: map

		if zoom > 0
			@map.setZoom zoom

	mapOptions =
		zoom: 0
		mapTypeId: google.maps.MapTypeId[@options.mapType]
		streetViewControl: false

	if @data.atts.googleMap
		_.extend mapOptions, @data.atts.googleMap

	@map = new google.maps.Map @find('.js-map'), mapOptions

	@map.setCenter new google.maps.LatLng @options.defaultLat, @options.defaultLng
	@map.setZoom @options.zoom

	if @data.atts.searchBox
		input = @find('.js-search')

		@map.controls[google.maps.ControlPosition.TOP_LEFT].push input
		searchBox = new google.maps.places.SearchBox input

		google.maps.event.addListener searchBox, 'places_changed', =>
			location = searchBox.getPlaces()[0].geometry.location
			@setMarker @map, location
			@map.setCenter location

		$(input).removeClass('af-map-search-box-hidden')

	if @data.atts.autolocate and navigator.geolocation and not @data.value
		navigator.geolocation.getCurrentPosition (position) =>
			location = new google.maps.LatLng position.coords.latitude, position.coords.longitude
			@setMarker @map, location, @options.zoom
			@map.setCenter location

	if typeof @data.atts.rendered == 'function'
		@data.atts.rendered @map

	google.maps.event.addListener @map, 'click', (e) =>
		@setMarker @map, e.latLng

	@$('.js-map').closest('form').on 'reset', =>
		@data.marker and @data.marker.setMap null
		@map.setCenter new google.maps.LatLng @options.defaultLat, @options.defaultLng
		@map.setZoom @options?.zoom or 0

	@mapReady.set true

Template.afMap.rendered = ->
	@autorun =>
		GoogleMaps.loaded() and initTemplateAndGoogleMaps.apply this

Template.afMap.helpers
	schemaKey: ->
		Template.instance()._interceptValue @
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
