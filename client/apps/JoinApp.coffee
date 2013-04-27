class JoinView extends BaseView

  el: Templates.JoinView()

  elements:
    "#name": "nameInput"
    "#phone": "phoneInput"
    "#join": "joinButton"

  events:
    "click #join": "onClickJoin"

  goPath: () ->
    """/go/#{App.event().get("code")}"""

  onClickJoin: () ->
    $("label").removeClass("error")
    for i in @$el.find("input.required").filter(-> !@value)
      @blink($("label[for='#{$(i).attr('name')}']").addClass("error"), 3)
    return if @$el.find("label.error").length
 
    user = new UserModel({
      name: @nameInput.val()
      phone: @phoneInput.val().replace(/[^0-9]/g, "")
      event: App.event().id
    })
    user.save(null, { success: @onSaveSuccess, error: @onSaveError })

  onSaveSuccess: (user, response) =>
    window.location = @goPath()

  onSaveError: (user, response) =>
    alert("Hmmm, something went wrong.")

class JoinApp extends BaseApp

  _event: new EventModel(eventObj)

  event: () ->
    @_event

$ ->
  window.App = new JoinApp()
  App.activateView(new JoinView())
