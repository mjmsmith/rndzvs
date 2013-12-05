class JoinView extends BaseView

  attributes:
    style: "width: 100%; height: 100%"

  events:
    "click #join": "onClickJoin"

  goPath: () ->
    """/go/#{App.event().get("code")}"""

  render: () ->
    @$el.html(Templates.JoinView())
    @
    
  onClickJoin: () ->
    @$("label").removeClass("error")
    for i in @$el.find("input.required").filter(-> !@value)
      @blink(@$("label[for='#{$(i).attr('name')}']").addClass("error"), 3)
    return if @$el.find("label.error").length
 
    user = new UserModel({
      name: @$("#name").val()
      phone: @$("#phone").val().replace(/[^0-9]/g, "")
      eventId: App.event().id
    })
    user.save(null, { success: @onSaveSuccess, error: @onSaveError })

  onSaveSuccess: (user, response) =>
    window.location = @goPath()

  onSaveError: (user, response) =>
    alert("Hmmm, something went wrong.")

class JoinApp extends BaseApp

  _event: new EventModel(window.rndzvs.event)

  event: () ->
    @_event

$ ->
  window.App = new JoinApp()
  App.activateView(new JoinView())
