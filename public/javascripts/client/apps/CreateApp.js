(function() {
  var CreateApp, CreateEventView, CreateUserView, ExitView, SelectPlaceView, _ref, _ref1, _ref2, _ref3, _ref4,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  SelectPlaceView = (function(_super) {
    __extends(SelectPlaceView, _super);

    function SelectPlaceView() {
      this.onClickUse = __bind(this.onClickUse, this);
      this.onPlaceChanged = __bind(this.onPlaceChanged, this);
      this.onLocateFailure = __bind(this.onLocateFailure, this);
      this.onLocateSuccess = __bind(this.onLocateSuccess, this);      _ref = SelectPlaceView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    SelectPlaceView.prototype.el = Templates.SelectPlaceView();

    SelectPlaceView.prototype.map = null;

    SelectPlaceView.prototype.autocomplete = null;

    SelectPlaceView.prototype.marker = null;

    SelectPlaceView.prototype.infoWindow = null;

    SelectPlaceView.prototype.place = null;

    SelectPlaceView.prototype.elements = {
      "#search": "searchInput",
      "#map": "mapDiv",
      "#use": "useButton"
    };

    SelectPlaceView.prototype.events = {
      "click #use": "onClickUse"
    };

    SelectPlaceView.prototype.activate = function() {
      $("#title").text("select a place");
      navigator.geolocation.getCurrentPosition(this.onLocateSuccess, this.onLocateFailure);
      return SelectPlaceView.__super__.activate.apply(this, arguments);
    };

    SelectPlaceView.prototype.loadMap = function() {
      var options;

      options = {
        zoom: 12,
        center: App.userLatLng(),
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        mapTypeControl: false
      };
      this.map = new google.maps.Map(this.mapDiv.get(0), options);
      this.autocomplete = new google.maps.places.Autocomplete(this.searchInput.get(0));
      this.autocomplete.bindTo('bounds', this.map);
      return google.maps.event.addListener(this.autocomplete, "place_changed", this.onPlaceChanged);
    };

    SelectPlaceView.prototype.onLocateSuccess = function(position) {
      App.userLatLng(new google.maps.LatLng(position.coords.latitude, position.coords.longitude));
      return this.loadMap();
    };

    SelectPlaceView.prototype.onLocateFailure = function(error) {
      return this.loadMap();
    };

    SelectPlaceView.prototype.onPlaceChanged = function() {
      var _this = this;

      this.place = this.autocomplete.getPlace();
      if (this.place.geometry.viewport) {
        this.map.fitBounds(this.place.geometry.viewport);
      } else {
        this.map.setCenter(this.place.geometry.location);
      }
      this.map.setZoom(15);
      if (this.marker) {
        this.marker.setMap(null);
      }
      this.marker = new google.maps.Marker({
        map: this.map,
        position: this.place.geometry.location,
        title: this.place.name
      });
      google.maps.event.addListener(this.marker, "click", function() {
        return _this.infoWindow.open(_this.map, _this.marker);
      });
      this.infoWindow = new google.maps.InfoWindow({
        content: Templates.SelectPlaceInfoView({
          "place": this.place
        })
      });
      this.infoWindow.open(this.map, this.marker);
      return this.searchInput.val("");
    };

    SelectPlaceView.prototype.onClickUse = function() {
      var event;

      event = App.event();
      event.set({
        place: this.place.name,
        address: this.place.vicinity,
        latitude: this.place.geometry.location.lat(),
        longitude: this.place.geometry.location.lng()
      });
      return App.activateView(new CreateEventView());
    };

    return SelectPlaceView;

  })(BaseView);

  CreateEventView = (function(_super) {
    __extends(CreateEventView, _super);

    function CreateEventView() {
      this.onSaveError = __bind(this.onSaveError, this);
      this.onSaveSuccess = __bind(this.onSaveSuccess, this);
      this.onClickCreate = __bind(this.onClickCreate, this);      _ref1 = CreateEventView.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    CreateEventView.prototype.el = Templates.CreateEventView();

    CreateEventView.prototype.elements = {
      "#name": "nameInput",
      "#place": "placeInput",
      "#address": "addressInput",
      "#dateDay": "dateDaySelect",
      "#dateHour": "dateHourSelect",
      "#dateMinute": "dateMinuteSelect",
      "#dateAmPm": "dateAmPmSelect",
      "#create": "createButton"
    };

    CreateEventView.prototype.events = {
      "click #create": "onClickCreate"
    };

    CreateEventView.prototype.activate = function() {
      var dayIndex, days, event, hour, minute, startDayIndex, _i, _j, _k, _len, _len1, _ref2, _ref3, _ref4;

      $("#title").text("describe the event");
      event = App.event();
      if (event.get("name")) {
        this.nameInput.val(event.get("name"));
      }
      if (event.get("place")) {
        this.placeInput.val(event.get("place"));
      }
      if (event.get("address")) {
        this.addressInput.val(event.get("address"));
      }
      days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
      startDayIndex = (new Date().getDay() + 2) % 7;
      this.dateDaySelect.append("<option>Today</option>");
      this.dateDaySelect.append("<option>Tomorrow</option>");
      for (dayIndex = _i = startDayIndex, _ref2 = startDayIndex + 4; startDayIndex <= _ref2 ? _i <= _ref2 : _i >= _ref2; dayIndex = startDayIndex <= _ref2 ? ++_i : --_i) {
        this.dateDaySelect.append("<option>" + days[dayIndex % 7] + "</option>");
      }
      _ref3 = [12].concat([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
      for (_j = 0, _len = _ref3.length; _j < _len; _j++) {
        hour = _ref3[_j];
        this.dateHourSelect.append("<option>" + hour + "</option>");
      }
      _ref4 = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
      for (_k = 0, _len1 = _ref4.length; _k < _len1; _k++) {
        minute = _ref4[_k];
        this.dateMinuteSelect.append("<option>" + (("0" + minute).slice(-2)) + "</option>");
      }
      this.dateAmPmSelect.append("<option>AM</option><option>PM</option>");
      return CreateEventView.__super__.activate.apply(this, arguments);
    };

    CreateEventView.prototype.dateFromForm = function() {
      var date, time;

      date = new Date();
      date.setHours(0);
      date.setMinutes(0);
      date.setSeconds(0);
      date.setMilliseconds(0);
      time = date.getTime();
      time += this.dateDaySelect.prop("selectedIndex") * 24 * 60 * 60 * 1000;
      time += this.dateHourSelect.prop("selectedIndex") * 60 * 60 * 1000;
      if (this.dateAmPmSelect.prop("selectedIndex") === 1) {
        time += 12 * 60 * 60 * 1000;
      }
      time += this.dateMinuteSelect.prop("selectedIndex") * 5 * 60 * 1000;
      return new Date(time);
    };

    CreateEventView.prototype.onClickCreate = function() {
      var event, i, _i, _len, _ref2;

      $("label").removeClass("error");
      _ref2 = this.$el.find("input.required").filter(function() {
        return !this.value;
      });
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        i = _ref2[_i];
        this.blink($("label[for='" + ($(i).attr('name')) + "']").addClass("error"), 3);
      }
      if (this.$el.find("label.error").length) {
        return;
      }
      event = App.event();
      event.set({
        name: this.nameInput.val(),
        place: this.placeInput.val(),
        address: this.addressInput.val(),
        date: this.dateFromForm()
      });
      return event.save(null, {
        success: this.onSaveSuccess,
        error: this.onSaveError
      });
    };

    CreateEventView.prototype.onSaveSuccess = function(event, response) {
      return App.activateView(new CreateUserView());
    };

    CreateEventView.prototype.onSaveError = function(event, response) {
      return alert("Hmmm, something went wrong.");
    };

    return CreateEventView;

  })(BaseView);

  CreateUserView = (function(_super) {
    __extends(CreateUserView, _super);

    function CreateUserView() {
      this.onSaveError = __bind(this.onSaveError, this);
      this.onSaveSuccess = __bind(this.onSaveSuccess, this);
      this.onClickCreate = __bind(this.onClickCreate, this);      _ref2 = CreateUserView.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    CreateUserView.prototype.el = Templates.CreateUserView();

    CreateUserView.prototype.elements = {
      "#name": "nameInput",
      "#phone": "phoneInput",
      "#create": "createButton"
    };

    CreateUserView.prototype.events = {
      "click #create": "onClickCreate"
    };

    CreateUserView.prototype.activate = function() {
      $("#title").text("describe yourself");
      return CreateUserView.__super__.activate.apply(this, arguments);
    };

    CreateUserView.prototype.onClickCreate = function() {
      var i, user, _i, _len, _ref3;

      $("label").removeClass("error");
      _ref3 = this.$el.find("input.required").filter(function() {
        return !this.value;
      });
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        i = _ref3[_i];
        this.blink($("label[for='" + ($(i).attr('name')) + "']").addClass("error"), 3);
      }
      if (this.$el.find("label.error").length) {
        return;
      }
      user = App.user();
      user.set({
        name: this.nameInput.val(),
        phone: this.phoneInput.val().replace(/[^0-9]/g, ""),
        event: App.event().id
      });
      return user.save(null, {
        success: this.onSaveSuccess,
        error: this.onSaveError
      });
    };

    CreateUserView.prototype.onSaveSuccess = function(user, response) {
      return App.activateView(new ExitView());
    };

    CreateUserView.prototype.onSaveError = function(user, response) {
      return alert("Hmmm, something went wrong.");
    };

    return CreateUserView;

  })(BaseView);

  ExitView = (function(_super) {
    __extends(ExitView, _super);

    function ExitView() {
      this.onClickGo = __bind(this.onClickGo, this);
      this.onClickEmail = __bind(this.onClickEmail, this);      _ref3 = ExitView.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    ExitView.prototype.el = Templates.ExitView();

    ExitView.prototype.elements = {
      "#link": "linkDiv",
      "#email": "emailButton",
      "#go": "goButton"
    };

    ExitView.prototype.events = {
      "click #email": "onClickEmail",
      "click #go": "onClickGo"
    };

    ExitView.prototype.activate = function() {
      $("#title").text("done");
      this.linkDiv.html("Your event link is http://rndzvs.com" + (this.goPath())).show();
      return ExitView.__super__.activate.apply(this, arguments);
    };

    ExitView.prototype.goPath = function() {
      return "/go/" + (App.event().get("code"));
    };

    ExitView.prototype.onClickEmail = function() {
      var body;

      body = "Where: " + (App.event().get("place")) + " @ " + (App.event().get("address")) + "\n\nLink: http://rndzvs.com" + (this.goPath());
      body = body.replace("\n", "%0A");
      return window.location = "mailto:?subject=invitation to " + (App.event().get("name")) + "&body=" + body;
    };

    ExitView.prototype.onClickGo = function() {
      return window.location = this.goPath();
    };

    return ExitView;

  })(BaseView);

  CreateApp = (function(_super) {
    __extends(CreateApp, _super);

    function CreateApp() {
      _ref4 = CreateApp.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    CreateApp.prototype._userLatLng = new google.maps.LatLng(41, -74);

    CreateApp.prototype._event = new EventModel();

    CreateApp.prototype._user = new UserModel();

    CreateApp.prototype.userLatLng = function() {
      if (arguments.length) {
        this._userLatLng = arguments[0];
      }
      return this._userLatLng;
    };

    CreateApp.prototype.event = function() {
      if (arguments.length) {
        this._event = arguments[0];
      }
      return this._event;
    };

    CreateApp.prototype.user = function() {
      if (arguments.length) {
        this._user = arguments[0];
      }
      return this._user;
    };

    return CreateApp;

  })(BaseApp);

  $(function() {
    window.App = new CreateApp();
    return App.activateView(new SelectPlaceView());
  });

}).call(this);
