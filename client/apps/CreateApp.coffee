class SelectPlaceView extends BaseView

  map: null
  autocomplete: null
  marker: null
  infoWindow: null
  place: null

  attributes:
    style: "width: 100%; height: 100%"
  
  events:
    "click #use": "onClickUse"

  render: () ->
    @$el.html(Templates.SelectPlaceView())
    @
    
  activated: () ->
    $("#title").text("select a place")
    navigator.geolocation.getCurrentPosition(@onLocateSuccess, @onLocateFailure)

  loadMap: () ->
    options = {
      zoom: 12
      center: App.userLatLng()
      mapTypeId: google.maps.MapTypeId.ROADMAP
      mapTypeControl: false
    }

    @map = new google.maps.Map($("#map").get(0), options)

    @autocomplete = new google.maps.places.Autocomplete($("#search").get(0))
    @autocomplete.bindTo('bounds', @map)

    google.maps.event.addListener(@autocomplete, "place_changed", @onPlaceChanged)

  onLocateSuccess: (position) =>
    App.userLatLng(new google.maps.LatLng(position.coords.latitude, position.coords.longitude))
    @loadMap()

  onLocateFailure: (error) =>
    @loadMap()

  onPlaceChanged: () =>
    @place = @autocomplete.getPlace()
    if @place.geometry.viewport
      @map.fitBounds(@place.geometry.viewport)
    else
      @map.setCenter(@place.geometry.location)
    @map.setZoom(15)

    @marker.setMap(null) if @marker
    @marker = new google.maps.Marker({
      map: @map
      position: @place.geometry.location
      title: @place.name
    })
    google.maps.event.addListener(@marker, "click", () => @infoWindow.open(@map, @marker))

    @infoWindow = new google.maps.InfoWindow(content: Templates.SelectPlaceInfoView("place": @place))
    @infoWindow.open(@map, @marker)

    $("#search").val("")

  onClickUse: () =>
    event = App.event()

    event.set({
      place: @place.name
      address: @place.vicinity
      latitude: @place.geometry.location.lat()
      longitude: @place.geometry.location.lng()
    })

    App.activateView(new CreateEventView())

class CreateEventView extends BaseView

  attributes:
    style: "width: 100%; height: 100%"

  events:
    "click #create": "onClickCreate"

  render: () ->
    @$el.html(Templates.CreateEventView())
    @

  activated: () ->
    $("#title").text("describe the event")

    event = App.event()

    $("#name").val(event.get("name")) if event.get("name")
    $("#place").val(event.get("place")) if event.get("place")
    $("#address").val(event.get("address")) if event.get("address")

    days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    startDayIndex = (new Date().getDay() + 2) % 7

    $("#dateDay").append("<option>Today</option>")
    $("#dateDay").append("<option>Tomorrow</option>")
    for dayIndex in [startDayIndex..startDayIndex+4]
      $("#dateDay").append("<option>#{days[dayIndex%7]}</option>")

    $("#dateHour").append("<option>#{hour}</option>") for hour in [12].concat([1..11])
    $("#dateMinute").append("<option>#{("0"+minute).slice(-2)}</option>") for minute in [0,5,10,15,20,25,30,35,40,45,50,55]
    $("#dateAmPm").append("<option>AM</option><option>PM</option>")

  dateFromForm: () ->
    date = new Date()
    
    date.setHours(0)
    date.setMinutes(0)
    date.setSeconds(0)
    date.setMilliseconds(0)

    time = date.getTime()
    
    time += $("#dateDay").prop("selectedIndex") * 24*60*60*1000
    time += $("#dateHour").prop("selectedIndex") * 60*60*1000
    time += 12*60*60*1000 if $("#dateAmPm").prop("selectedIndex") == 1
    time += $("#dateMinute").prop("selectedIndex") * 5*60*1000

    new Date(time)

  onClickCreate: () =>
    $("label").removeClass("error")
    for i in @$el.find("input.required").filter(-> !@value)
      @blink($("label[for='#{$(i).attr('name')}']").addClass("error"), 3)
    return if @$el.find("label.error").length
    
    event = App.event()

    event.set({
      name: $("#name").val()
      place: $("#place").val()
      address: $("#address").val()
      date: @dateFromForm()
    })

    event.save(null, { success: @onSaveSuccess, error: @onSaveError })

  onSaveSuccess: (event, response) =>
    App.event(event)
    App.activateView(new CreateUserView())

  onSaveError: (event, response) =>
    alert("Hmmm, something went wrong.")

class CreateUserView extends BaseView

  attributes:
    style: "width: 100%; height: 100%"

  events:
    "click #create": "onClickCreate"

  render: () ->
    @$el.html(Templates.CreateUserView())
    @

  activated: () ->
    $("#title").text("describe yourself")

  onClickCreate: () =>
    $("label").removeClass("error")
    for i in @$el.find("input.required").filter(-> !@value)
      @blink($("label[for='#{$(i).attr('name')}']").addClass("error"), 3)
    return if @$el.find("label.error").length

    user = App.user()

    user.set({
      name: $("#name").val()
      phone: $("#phone").val().replace(/[^0-9]/g, "")
      eventId: App.event().id
    })

    user.save(null, { success: @onSaveSuccess, error: @onSaveError })

  onSaveSuccess: (user, response) =>
    App.user(user)
    App.activateView(new ExitView())

  onSaveError: (user, response) =>
    alert("Hmmm, something went wrong.")

class ExitView extends BaseView

  attributes:
    style: "width: 100%; height: 100%"

  events:
    "click #email": "onClickEmail"
    "click #go": "onClickGo"

  render: () ->
    @$el.html(Templates.ExitView())
    @

  activated: () ->
    $("#title").text("done")
    $("#link").html("Your event link is http://rndzvs.com#{@goPath()}").show()

  goPath: () ->
    """/go/#{App.event().get("code")}"""

  onClickEmail: () =>
    body = """Where: #{App.event().get("place")} @ #{App.event().get("address")}\n
              Link: http://rndzvs.com#{@goPath()}"""
    body = body.replace("\n", "%0A")
    window.location = """mailto:?subject=invitation to #{App.event().get("name")}&body=#{body}"""

  onClickGo: () =>
    window.location = @goPath()

class CreateApp extends BaseApp

  _userLatLng: new google.maps.LatLng(41, -74)
  _event: new EventModel()
  _user: new UserModel()

  userLatLng: () ->
    @_userLatLng = arguments[0] if arguments.length
    @_userLatLng

  event: () ->
    @_event = arguments[0] if arguments.length
    @_event

  user: () ->
    @_user = arguments[0] if arguments.length
    @_user

$ ->
  window.App = new CreateApp()
  App.activateView(new SelectPlaceView())
