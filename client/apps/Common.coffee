# Base classes.

class BaseModel extends Backbone.Model

class BaseCollection extends Backbone.Collection

# Events.

class @EventModel extends BaseModel

  urlRoot: "/events"

  dateTitle: () ->
    date = new Date(@get("date"))
    hour = date.getHours()
    ampm = if hour < 12 then "AM" else "PM"
    
    if hour == 0
      hour = 12
    else if hour > 12
      hour -= 12

    ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][date.getDay()] +
    " #{hour}:#{("0"+date.getMinutes()).slice(-2)} #{ampm}"

class @EventCollection extends BaseCollection

  model: EventModel
  url: "/events"

# Users.

class @UserModel extends BaseModel

  urlRoot: "/users"

class @UserCollection extends BaseCollection

  model: UserModel
  url: "/users"

# Views.

class @BaseView extends Backbone.View

  activated: () ->
  
  blink: (element, count) ->
    return if !(count--)
    $(element).fadeOut "fast", () =>
      $(element).fadeIn "fast", () =>
        @blink(element, count)

class @BaseApp

  _activeView: null

  activateView: (view) ->
    @_activeView.remove() if @_activeView?
    @_activeView = view
    $("#window").html(@_activeView.render().el)
    @_activeView.activated()
