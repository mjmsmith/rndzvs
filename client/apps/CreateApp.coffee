class SelectPlaceView extends BaseView

  el: Templates.SelectPlaceView()
  map: null
  autocomplete: null
  marker: null
  infoWindow: null
  place: null

  elements:
    "#search": "searchInput"
    "#map": "mapDiv"
    "#use": "useButton"

  events:
    "click #use": "onClickUse"

  activate: () ->
    $("#title").text("select a place")
    navigator.geolocation.getCurrentPosition(@onLocateSuccess, @onLocateFailure)
    super

  loadMap: () ->
    options = {
      zoom: 12
      center: App.userLatLng()
      mapTypeId: google.maps.MapTypeId.ROADMAP
      mapTypeControl: false
    }

    @map = new google.maps.Map(@mapDiv.get(0), options)

    @autocomplete = new google.maps.places.Autocomplete(@searchInput.get(0))
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

    @searchInput.val("")

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

  el: Templates.CreateEventView()

  elements:
    "#name": "nameInput"
    "#place": "placeInput"
    "#address": "addressInput"
    "#dateDay": "dateDaySelect"
    "#dateHour": "dateHourSelect"
    "#dateMinute": "dateMinuteSelect"
    "#dateAmPm": "dateAmPmSelect"
    "#create": "createButton"

  events:
    "click #create": "onClickCreate"

  activate: () ->
    $("#title").text("describe the event")

    event = App.event()

    @nameInput.val(event.get("name")) if event.get("name")
    @placeInput.val(event.get("place")) if event.get("place")
    @addressInput.val(event.get("address")) if event.get("address")

    days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    startDayIndex = (new Date().getDay() + 2) % 7

    @dateDaySelect.append("<option>Today</option>")
    @dateDaySelect.append("<option>Tomorrow</option>")
    for dayIndex in [startDayIndex..startDayIndex+4]
      @dateDaySelect.append("<option>#{days[dayIndex%7]}</option>")

    @dateHourSelect.append("<option>#{hour}</option>") for hour in [12].concat([1..11])
    @dateMinuteSelect.append("<option>#{("0"+minute).slice(-2)}</option>") for minute in [0,5,10,15,20,25,30,35,40,45,50,55]
    @dateAmPmSelect.append("<option>AM</option><option>PM</option>")

    super

  dateFromForm: () ->
    date = new Date()
    
    date.setHours(0)
    date.setMinutes(0)
    date.setSeconds(0)
    date.setMilliseconds(0)

    time = date.getTime()
    
    time += (@dateDaySelect.prop("selectedIndex") * 24*60*60*1000)
    time += (@dateHourSelect.prop("selectedIndex") * 60*60*1000)
    time += 12*60*60*1000 if @dateAmPmSelect.prop("selectedIndex") == 1
    time += (@dateMinuteSelect.prop("selectedIndex") * 5*60*1000);

    new Date(time)

  onClickCreate: () =>
    $("label").removeClass("error")
    for i in @$el.find("input.required").filter(-> !@value)
      @blink($("label[for='#{$(i).attr('name')}']").addClass("error"), 3)
    return if @$el.find("label.error").length
    
    event = App.event()

    event.set({
      name: @nameInput.val()
      place: @placeInput.val()
      address: @addressInput.val()
      date: @dateFromForm()
    })

    event.save(null, { success: @onSaveSuccess, error: @onSaveError })

  onSaveSuccess: (event, response) =>
    App.activateView(new CreateUserView())

  onSaveError: (event, response) =>
    alert("Hmmm, something went wrong.")

class CreateUserView extends BaseView

  el: Templates.CreateUserView()

  elements:
    "#name": "nameInput"
    "#phone": "phoneInput"
    "#create": "createButton"

  events:
    "click #create": "onClickCreate"

  activate: () ->
    $("#title").text("describe yourself")
    super

  onClickCreate: () =>
    $("label").removeClass("error")
    for i in @$el.find("input.required").filter(-> !@value)
      @blink($("label[for='#{$(i).attr('name')}']").addClass("error"), 3)
    return if @$el.find("label.error").length

    user = App.user()

    user.set({
      name: @nameInput.val()
      phone: @phoneInput.val().replace(/[^0-9]/g, "")
      eventId: App.event().id
    })

    user.save(null, { success: @onSaveSuccess, error: @onSaveError })

  onSaveSuccess: (user, response) =>
    App.activateView(new ExitView())

  onSaveError: (user, response) =>
    alert("Hmmm, something went wrong.")

class ExitView extends BaseView

  el: Templates.ExitView()

  elements:
    "#link": "linkDiv"
    "#email": "emailButton"
    "#go": "goButton"

  events:
    "click #email": "onClickEmail"
    "click #go": "onClickGo"

  activate: () ->
    $("#title").text("done")
    @linkDiv.html("Your event link is http://rndzvs.com#{@goPath()}").show()
    super

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
