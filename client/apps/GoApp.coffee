class EventView extends BaseView

  el: Templates.EventView()
  map: null
  placeMarker: null
  users: null
  userMarkers: {}
  infoWindow: null

  elements:
    "#details": "detailsDiv"
    "#place": "placeDiv"
    "#address": "addressDiv"
    "#date": "dateDiv"
    "#map": "mapDiv"
    "#users": "usersSelect"

  events:
    "click #details": "onClickDetails"
    "change #users": "onSelectUser"

  activate: () ->
    event = App.event()

    # Set event info.

    @placeDiv.text(event.get("place"))
    @addressDiv.text(event.get("address"))
    @dateDiv.text(event.dateTitle())

    # Create map and event marker.

    position = new google.maps.LatLng(event.get("latitude"), event.get("longitude"))

    @map = new google.maps.Map(@mapDiv.get(0), {
      zoom: 14
      center: position
      mapTypeId: google.maps.MapTypeId.ROADMAP
      mapTypeControl: false
      noClear: true
    })

    @placeMarker = new google.maps.Marker({
      map: @map
      position: position
      title: event.get("place")
    })
    google.maps.event.addListener(@placeMarker, "click", () => @openInfoWindow(null))

    # Setup for updating users.

    @users = new UserCollection()
    setTimeout(@onTimeout, 5000)

    super

  fetchUsers: () ->
    @users.fetch({
      success: @onFetchSuccess
      error: @onFetchError
    })

  updateUsers: () ->
    for user in @users.models
      @updateUserMarker(user) if user.get("latitude") && user.get("longitude")

    @usersSelect.html("""<option disabled="true">who's where?</option>""")
    @usersSelect.append(Templates.UserOption({ user })) for user in @users.models

  updateUserMarker: (user) ->
    marker = @userMarkers[user.id]
    
    if marker
      marker.setPosition(new google.maps.LatLng(user.get("latitude"), user.get("longitude")))
    else
      marker = @userMarkers[user.id] = @markerForUser(user)
      view = this
      do (user, marker) ->
        google.maps.event.addListener(marker, "click", () => view.openInfoWindow(user))

  openInfoWindow: (user) ->
    @infoWindow.close() if @infoWindow

    if user
      @infoWindow = @infoWindowForUser(user)
      @infoWindow.open(@map, @userMarkers[user.id])
    else
      @infoWindow = new google.maps.InfoWindow({
        content: Templates.PlaceInfo({ event: App.event() })
      })
      @infoWindow.open(@map, @placeMarker)

  markerForUser: (user) ->
    position = new google.maps.LatLng(user.get("latitude"), user.get("longitude"))
    color = if user.id == App.user().id then "blue" else "green"
    icon = new google.maps.MarkerImage(
      "/images/pins/#{color}.png",
      new google.maps.Size(17,31),
      new google.maps.Point(0,0),
      new google.maps.Point(9,31)
    )
    shadow = new google.maps.MarkerImage(
      "/images/pins/shadow.png",
      new google.maps.Size(37,31),
      new google.maps.Point(0,0),
      new google.maps.Point(9,31)
    )
    shape = {
      coord: [
        11,0,13,1,14,2,14,3,15,4,15,5,16,6,16,7,16,8,15,9,15,10,15,11,14,12,13,13,12,14,10,15,9,16,9,17,9,18,9,
        19,9,20,9,21,9,22,9,23,9,24,9,25,9,26,9,27,9,28,9,29,9,30,7,30,7,29,7,28,7,27,7,26,7,25,7,24,7,23,7,22,
        7,21,7,20,7,19,7,18,7,17,7,16,6,15,4,14,3,13,2,12,1,11,1,10,0,9,0,8,0,7,0,6,1,5,1,4,2,3,2,2,3,1,5,0,11,0
      ],
      type: "poly"
    }

    new google.maps.Marker({
      map: @map
      position: position
      icon: icon
      shadow: shadow
      shape: shape
      animation: google.maps.Animation.DROP
      title: user.get("name")
    })

  infoWindowForUser: (user) ->
    content = Templates.NameInfo({ user })
    content += Templates.PhoneInfo({ user }) if user.get("phone")
    new google.maps.InfoWindow({ content })

  onTimeout: () =>
    navigator.geolocation.getCurrentPosition(@onLocateSuccess, @onLocateFailure)

  onLocateSuccess: (position) =>
    user = App.user()
    user.set({
      latitude: position.coords.latitude
      longitude: position.coords.longitude
    })
    user.save(null, { success: @onSaveSuccess, error: @onSaveError })

  onLocateFailure: (error) =>
    @fetchUsers()

  onSaveSuccess: (user, response) =>
    console.log "saved"
    @fetchUsers()

  onSaveError: (user, response) =>
    @fetchUsers()

  onFetchSuccess: (users, response) =>
    console.log "updated"
    @updateUsers()
    setTimeout(@onTimeout, 5000)

  onFetchError: (users, response) =>
    setTimeout(@onTimeout, 5000)

  onSelectUser: () =>
    @openInfoWindow(@users.get(@usersSelect.val()))

  onClickDetails: () =>
    @openInfoWindow(null)

class GoApp extends BaseApp

  _user: new UserModel(userObj)
  _event: new EventModel(eventObj)

  user: () ->
    @_user

  event: () ->
    @_event

$ ->
  window.App = new GoApp()
  App.activateView(new EventView())
