(function() {
  var JoinApp, JoinView, _ref, _ref1,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  JoinView = (function(_super) {
    __extends(JoinView, _super);

    function JoinView() {
      this.onSaveError = __bind(this.onSaveError, this);
      this.onSaveSuccess = __bind(this.onSaveSuccess, this);      _ref = JoinView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    JoinView.prototype.el = Templates.JoinView();

    JoinView.prototype.elements = {
      "#name": "nameInput",
      "#phone": "phoneInput",
      "#join": "joinButton"
    };

    JoinView.prototype.events = {
      "click #join": "onClickJoin"
    };

    JoinView.prototype.goPath = function() {
      return "/go/" + (App.event().get("code"));
    };

    JoinView.prototype.onClickJoin = function() {
      var i, user, _i, _len, _ref1;

      $("label").removeClass("error");
      _ref1 = this.$el.find("input.required").filter(function() {
        return !this.value;
      });
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        i = _ref1[_i];
        this.blink($("label[for='" + ($(i).attr('name')) + "']").addClass("error"), 3);
      }
      if (this.$el.find("label.error").length) {
        return;
      }
      user = new UserModel({
        name: this.nameInput.val(),
        phone: this.phoneInput.val().replace(/[^0-9]/g, ""),
        event: App.event().id
      });
      return user.save(null, {
        success: this.onSaveSuccess,
        error: this.onSaveError
      });
    };

    JoinView.prototype.onSaveSuccess = function(user, response) {
      return window.location = this.goPath();
    };

    JoinView.prototype.onSaveError = function(user, response) {
      return alert("Hmmm, something went wrong.");
    };

    return JoinView;

  })(BaseView);

  JoinApp = (function(_super) {
    __extends(JoinApp, _super);

    function JoinApp() {
      _ref1 = JoinApp.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    JoinApp.prototype._event = new EventModel(eventObj);

    JoinApp.prototype.event = function() {
      return this._event;
    };

    return JoinApp;

  })(BaseApp);

  $(function() {
    window.App = new JoinApp();
    return App.activateView(new JoinView());
  });

}).call(this);
