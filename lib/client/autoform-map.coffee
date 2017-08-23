KEY_ENTER = 13
defaults =
	mapType: 'roadmap'
	defaultLat: 1
	defaultLng: 1
	geolocation: false
	searchBox: false
	autolocate: true
	zoom: 8,
	libraries: 'places',
	key: '',
	language: 'en',
	direction: 'ltr',
	geoCoding: false,
	geoCodingCallBack: null,
	animateMarker: false,
	radius: 100
markers = []

AutoForm.addInputType 'map',
	template: 'afMap'
	valueOut: ->
		node = $(@context)

		lat = node.find('.js-lat').val()
		lng = node.find('.js-lng').val()
		radius = node.find('.radius').val()
		poly = node.find('.poly').val()

		out = {}
		if lat?.length > 0 and lng?.length > 0
			out.lat = lat
			out.lng = lng
		if radius?.length > 0
			out.radius = radius
		if poly?.length > 0
			out.poly = poly
		out
	contextAdjust: (ctx) ->
		ctx.loading = new ReactiveVar(false)
		ctx
	valueConverters:
		string: (value) ->
			retVal = ""
			if @attr('reverse')
				retVal = "#{value.lng},#{value.lat}"
			else
				retVal = "#{value.lat},#{value.lng}"

			if @attr('drawCircle')
				retVal = retVal + ",#{value.radius}"
			
			if @attr('poly')
				retVal = retVal + ",#{value.poly}"

			retVal
		numberArray: (value) ->
			retVal = [value.lng, value.lat]
			if @attr('drawCircle')
				retVal.push(value.radius)

			retVal

Template.afMap.created = ->
	@locationIsAllowed = new ReactiveVar false
	@mapReady = new ReactiveVar false
	@options = _.extend {}, defaults, @data.atts

	if typeof google != 'object' || typeof google.maps != 'object'
		GoogleMaps.load(libraries: @options.libraries, key: @options.key, language: @options.language)

	@_stopInterceptValue = false
	@_interceptValue = (ctx) ->
		t = Template.instance()
		if t.mapReady.get() and ctx.value and not t._stopInterceptValue
			location = if typeof ctx.value == 'string' then ctx.value.split ',' else if ctx.value.hasOwnProperty 'lat' then [ctx.value.lat, ctx.value.lng] else [ctx.value[1], ctx.value[0]]
			location = new google.maps.LatLng parseFloat(location[0]), parseFloat(location[1])
			t.data.radius = if ctx.value.hasOwnProperty 'radius' then ctx.value.radius else 100
			t.setMarker t.map, location, t.options.zoom
			t.map.setCenter location
			t._stopInterceptValue = true
			if isNaN(t.data.marker.position.lat())
				initTemplateAndGoogleMaps.apply t

	@_getMyLocation = (t) ->
		unless t.map? and navigator.geolocation and not t.data.loading.get() then return false

		t.data.loading.set true
		navigator.geolocation.getCurrentPosition (position) =>
			location = new google.maps.LatLng position.coords.latitude, position.coords.longitude
			t.setMarker t.map, location, t.options.zoom
			t.map.setCenter location
			t.data.loading.set false

	@_getDefaultLocation = (t) ->
		unless t.map? and navigator.geolocation then return false
		
		t.data.loading.set true
		location = new google.maps.LatLng t.options.defaultLat, t.options.defaultLng
		t.map.setCenter location
		t.setMarker t.map, location, t.options.zoom
		t.data.loading.set false

displayMapError = (error, t) ->
	# Using .parents instead of .closest, for custom usage in blaze template
	$(t.firstNode).parents('.location').addClass('has-error');
	t.locationIsAllowed.set false
	console.log
	setTimeout ->
		initTemplateAndGoogleMaps.apply t
	, 3000

initTemplateAndGoogleMaps = ->
	@data.marker = undefined
	@locationIsAllowed.set true

	@drawStaticMarkers = ->
		for m, i in @options.staticMarkers
			sMarker = null
			
			if @data.sMarkers? and @data.sMarkers.length > 0
				sMarker = lookupArray @data.sMarkers, 'placeId', m.location.placeId
			else
				@data.sMarkers = []

			if sMarker?
				sMarkerIndex = @data.sMarkers.indexOf(sMarker)
				if sMarker.map != @map
					@data.sMarkers[sMarkerIndex].marker.setMap @map
			else
				sMarkerOpt = 
					position: {lat: Number(m.location.position.lat), lng: Number(m.location.position.lng)}
					placeId: m.location.placeId
					map: @map
					zIndex: 1
				if m.animateMarker
					sMarkerOpt.animation = google.maps.Animation.DROP
				if m.customIcon
					icon = 
						url: m.icon.url
						anchor: new google.maps.Point(m.icon.point.x, m.icon.point.y)
						scaledSize: new google.maps.Size(m.icon.size.w, m.icon.size.h)
					sMarkerOpt.icon = icon
				mkr = new google.maps.Marker sMarkerOpt
				sMarker =
					placeId: m.location.placeId
					map: @map
					marker: mkr
				
				@data.sMarkers.push(sMarker)

	@drawCircle = (location, radius) =>
		if not radius?
			radius = if @data.radius? then @data.radius else @options.radius
		if @data.marker.circle?
			@data.marker.circle.setMap null
			@data.marker.circle = null

		if not radius?
			radius = 100

		@data.marker.circle = new google.maps.Circle ({
			strokeColor: '#FFFFFF',
			strokeOpacity: 0.8,
			strokeWeight: 2,
			fillColor: '#809FB3',
			fillOpacity: 0.35,
			map: @map,
			center: location,
			editable: true,
			zIndex: 5,
			radius: radius
		})

		if @data.marker?.circle?
			@$('.radius').val(radius)
			window[@options.radiusChangedCallback](@, @data.marker.circle.getRadius())

		google.maps.event.addListener @data.marker.circle, 'click', (e) =>
			@setMarker @map, e.latLng, @map.zoom

		google.maps.event.addListener @data.marker.circle, 'radius_changed', (e) =>
			if not @data.marker?
				if markers[@data.name]?
					@data.marker = markers[@data.name].marker
					@data.marker.setMap(markers[@data.name].map)
					@data.marker.setPosition location
				else
					e.preventDefault()
					return false
			@$('.radius').val(Math.round(@data.marker.circle.getRadius()))
			window[@options.radiusChangedCallback](@, @data.marker.circle.getRadius())
		
		google.maps.event.addListener @data.marker.circle, 'center_changed', (e) =>
			if not @data.marker?
				if markers[@data.name]?
					@data.marker = markers[@data.name].marker
					@data.marker.setMap(markers[@data.name].map)
					@data.marker.setPosition location
				else
					e.preventDefault()
					return false
			window[@options.centerChangedCallback](@, @data.marker)

	@setMarker = (map, location, zoom=0) =>
		if not @data? or not @map?
			return false

		@$('.js-lat').val(location.lat())
		@$('.js-lng').val(location.lng())

		if @data.marker
			@data.marker.setPosition location
			if @options.drawCircle
				if @data.marker.circle?
					@drawCircle location, @data.marker.circle.getRadius()
				else
					@drawCircle location
			if @data.marker.map != @map
				@data.marker.setMap(@map)
		else if markers[@data.name]?
			@data.marker = markers[@data.name].marker
			@data.marker.setMap(markers[@data.name].map)
			@data.marker.setPosition location
			if @options.drawCircle
				if @data.marker.circle?
					@drawCircle location, @data.marker.circle.getRadius()
				else
					@drawCircle location
		else
			markerOpts = 
				position: location
				map: @map
				zIndex: 5
			if @options.animateMarker
				markerOpts.animation = google.maps.Animation.DROP
			if @options.customIcon
				icon = 
					url: @options.icon.url
					anchor: new google.maps.Point(@options.icon.point.x, @options.icon.point.y)
					scaledSize: new google.maps.Size(@options.icon.size.w, @options.icon.size.h)
				markerOpts.icon = icon
			@data.marker = new google.maps.Marker markerOpts

			if @options.drawCircle and not isNaN(location.lat())
				@drawCircle location

			markers[@data.name] = {marker: @data.marker, map: @map}
		
		# Fix: triggering resize to avoid pre-loaded map different size
		google.maps.event.trigger(@map, 'resize')

		if @options.staticMarkers?
			@drawStaticMarkers()

		if zoom > 0
			@map.setZoom zoom

		if @options.geoCoding
			if !@geocoder?
				@geocoder = new google.maps.Geocoder

			if @geocoder? and @options.geoCodingCallBack?
				window[@options.geoCodingCallBack](@, @geocoder, location)

		# Set polygon default paths if not set
		if @options.drawPoly
			curVal = @$('.poly').val()
			if not @data.value?.poly? and curVal == '' and @data.marker?.position?
				m = 100
				coef = m * 0.000008983
				lat = @data.marker.position.lat()
				lng = @data.marker.position.lng()
				# new_lat  = lat + coef;
				# new_long = lng + coef / Math.cos(lat * 0.018);
				p1 = {lat: lat + coef, lng: lng + coef / Math.cos(lat * 0.018)}
				p2 = {lat: lat + coef, lng: lng - coef / Math.cos(lat * 0.018)}
				p3 = {lat: lat - coef, lng: lng - coef / Math.cos(lat * 0.018)}
				p4 = {lat: lat - coef, lng: lng + coef / Math.cos(lat * 0.018)}
				defaultPaths = [p1, p2, p3, p4]
				@data.polygon.setPaths defaultPaths
				@data.polyPaths = defaultPaths
				@$('.poly').val(JSON.stringify(defaultPaths))
				if @options.polyPathBinding
					window[@options.polyPathBinding](@)

	mapOptions =
		zoom: 0
		mapTypeId: google.maps.MapTypeId[@options.mapType.toUpperCase()]
		streetViewControl: false

	if @data.atts.googleMap
		_.extend mapOptions, @data.atts.googleMap

	@map = new google.maps.Map @find('.js-map'), mapOptions

	if @data.atts.searchBox
		input = @find('.js-search')

		if @options.direction == 'rtl'
			@map.controls[google.maps.ControlPosition.TOP_RIGHT].push input
		else
			@map.controls[google.maps.ControlPosition.TOP_LEFT].push input
		searchBox = new google.maps.places.SearchBox input

		google.maps.event.addListener searchBox, 'places_changed', =>
			location = searchBox.getPlaces()[0].geometry.location
			@setMarker @map, location, @options.zoom
			@map.setCenter location

		$(input).removeClass('af-map-search-box-hidden')

	if @data.atts.geolocation
		myLocation = @find('.js-locate')
		myLocation.addEventListener 'click', => @._getMyLocation(@)
		if @options.direction == 'rtl'
			@map.controls[google.maps.ControlPosition.TOP_LEFT].push myLocation
		else
			@map.controls[google.maps.ControlPosition.TOP_RIGHT].push myLocation

	if @options.autolocate and navigator.geolocation
		if not @data.value and @map?
			navigator.geolocation.getCurrentPosition (position) =>
				if @options.geoCoding
					@geocoder = new google.maps.Geocoder
				$(@firstNode).parents('.location').removeClass('has-error');
				location = new google.maps.LatLng position.coords.latitude, position.coords.longitude
				@setMarker @map, location, @options.zoom
				@map.setCenter location
			, (error) =>
				displayMapError(error, @)
	else
		@._getDefaultLocation @

	if typeof @data.atts.rendered == 'function'
		@data.atts.rendered @map

	google.maps.event.addListener @map, 'click', (e) =>
		if @options.customMapClick && @options.customMapClickCallback
			window[@options.customMapClickCallback](e, @)
		else
			@setMarker @map, e.latLng, @map.zoom

	@$('.js-map').closest('form').on 'reset', =>
		if @map?
			if @options.autolocate
				@._getMyLocation @
			else
				@._getDefaultLocation @
		
	if @options.drawPoly
		@data.polygon = new google.maps.Polygon(@options.polyOptions)
		google.maps.event.addListener @data.polygon, 'click', (e) =>
			if @options.customPolyClick && @options.customPolyClickCallback
				window[@options.customPolyClickCallback](e, @)
			else
				@setMarker @map, e.latLng, @map.zoom
		@data.polygon.setVisible(false)
		@data.polygon.setMap(@map)

		# Set polygon paths from DB
		if @data.value.poly?
			@data.polygon.setPaths JSON.parse(@data.value.poly)
			@data.polyPaths = JSON.parse(@data.value.poly)
			@$('.poly').val(@data.value.poly)
			if @options.polyPathBinding
				window[@options.polyPathBinding](@)

		@hidePoly = ->
			@data.polygon.setVisible(false)
		@showPoly = ->
			@data.polygon.setVisible(true)
		@clearPoly = ->
			@data.polygon.setPaths []
			@data.polyPaths = []
			@$('.poly').val('')

	@mapReady.set true

Template.afMap.onRendered ->
	@autorun =>
		GoogleMaps.loaded() and initTemplateAndGoogleMaps.apply this

Template.afMap.onDestroyed ->
	@map = null
	delete markers[@data.name]
	if @options.geoCoding
		@geocoder = null

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
		t._getMyLocation(t)

	'keydown .js-search': (e) ->
		if e.keyCode == KEY_ENTER then e.preventDefault()

	'click .hidePoly': (e, t) ->
		t.hidePoly()

	'click .showPoly': (e, t) ->
		t.showPoly()

	'click .clear-poly': (e, t) ->
		t.clearPoly()
