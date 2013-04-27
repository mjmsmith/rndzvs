(function() {
  var EventView, GoApp, _ref, _ref1,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventView = (function(_super) {
    __extends(EventView, _super);

    function EventView() {
      this.onClickDetails = __bind(this.onClickDetails, this);
      this.onSelectUser = __bind(this.onSelectUser, this);
      this.onFetchError = __bind(this.onFetchError, this);
      this.onFetchSuccess = __bind(this.onFetchSuccess, this);
      this.onSaveError = __bind(this.onSaveError, this);
      this.onSaveSuccess = __bind(this.onSaveSuccess, this);
      this.onLocateFailure = __bind(this.onLocateFailure, this);
      this.onLocateSuccess = __bind(this.onLocateSuccess, this);
      this.onTimeout = __bind(this.onTimeout, this);      _ref = EventView.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    EventView.prototype.el = Templates.EventView({
      user: window.userObj
    });

    EventView.prototype.map = null;

    EventView.prototype.placeMarker = null;

    EventView.prototype.users = null;

    EventView.prototype.userMarkers = {};

    EventView.prototype.infoWindow = null;

    EventView.prototype.elements = {
      "#details": "detailsDiv",
      "#place": "placeDiv",
      "#address": "addressDiv",
      "#date": "dateDiv",
      "#map": "mapDiv",
      "#users": "usersSelect"
    };

    EventView.prototype.events = {
      "click #details": "onClickDetails",
      "change #users": "onSelectUser"
    };

    EventView.prototype.activate = function() {
      var event, position,
        _this = this;

      event = App.event();
      this.placeDiv.text(event.get("place"));
      this.addressDiv.text(event.get("address"));
      this.dateDiv.text(event.dateTitle());
      position = new google.maps.LatLng(event.get("latitude"), event.get("longitude"));
      this.map = new google.maps.Map(this.mapDiv.get(0), {
        zoom: 14,
        center: position,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        mapTypeControl: false,
        noClear: true
      });
      this.placeMarker = new google.maps.Marker({
        map: this.map,
        position: position,
        title: event.get("place")
      });
      google.maps.event.addListener(this.placeMarker, "click", function() {
        return _this.openInfoWindow(null);
      });
      this.users = new UserCollection();
      setTimeout(this.onTimeout, 5000);
      return EventView.__super__.activate.apply(this, arguments);
    };

    EventView.prototype.fetchUsers = function() {
      return this.users.fetch({
        data: {
          event: App.event().id
        },
        success: this.onFetchSuccess,
        error: this.onFetchError
      });
    };

    EventView.prototype.updateUsers = function() {
      var user, _i, _j, _len, _len1, _ref1, _ref2, _results;

      _ref1 = this.users.models;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        user = _ref1[_i];
        if (user.get("latitude") && user.get("longitude")) {
          this.updateUserMarker(user);
        }
      }
      this.usersSelect.html("<option disabled=\"true\">who's where?</option>");
      _ref2 = this.users.models;
      _results = [];
      for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
        user = _ref2[_j];
        _results.push(this.usersSelect.append(this.userOptionTemplate({
          user: user
        })));
      }
      return _results;
    };

    EventView.prototype.updateUserMarker = function(user) {
      var marker, view;

      marker = this.userMarkers[user.id];
      if (marker) {
        return marker.setPosition(new google.maps.LatLng(user.get("latitude"), user.get("longitude")));
      } else {
        marker = this.userMarkers[user.id] = this.markerForUser(user);
        view = this;
        return (function(user, marker) {
          var _this = this;

          return google.maps.event.addListener(marker, "click", function() {
            return view.openInfoWindow(user);
          });
        })(user, marker);
      }
    };

    EventView.prototype.openInfoWindow = function(user) {
      if (this.infoWindow) {
        this.infoWindow.close();
      }
      if (user) {
        this.infoWindow = this.infoWindowForUser(user);
        return this.infoWindow.open(this.map, this.userMarkers[user.id]);
      } else {
        this.infoWindow = new google.maps.InfoWindow({
          content: this.placeInfoTemplate({
            App: App
          })
        });
        return this.infoWindow.open(this.map, this.placeMarker);
      }
    };

    EventView.prototype.markerForUser = function(user) {
      var color, icon, position, shadow, shape;

      position = new google.maps.LatLng(user.get("latitude"), user.get("longitude"));
      color = user.id === App.user().id ? "blue" : "green";
      icon = new google.maps.MarkerImage("/images/pins/" + color + ".png", new google.maps.Size(17, 31), new google.maps.Point(0, 0), new google.maps.Point(9, 31));
      shadow = new google.maps.MarkerImage("/images/pins/shadow.png", new google.maps.Size(37, 31), new google.maps.Point(0, 0), new google.maps.Point(9, 31));
      shape = {
        coord: [11, 0, 13, 1, 14, 2, 14, 3, 15, 4, 15, 5, 16, 6, 16, 7, 16, 8, 15, 9, 15, 10, 15, 11, 14, 12, 13, 13, 12, 14, 10, 15, 9, 16, 9, 17, 9, 18, 9, 19, 9, 20, 9, 21, 9, 22, 9, 23, 9, 24, 9, 25, 9, 26, 9, 27, 9, 28, 9, 29, 9, 30, 7, 30, 7, 29, 7, 28, 7, 27, 7, 26, 7, 25, 7, 24, 7, 23, 7, 22, 7, 21, 7, 20, 7, 19, 7, 18, 7, 17, 7, 16, 6, 15, 4, 14, 3, 13, 2, 12, 1, 11, 1, 10, 0, 9, 0, 8, 0, 7, 0, 6, 1, 5, 1, 4, 2, 3, 2, 2, 3, 1, 5, 0, 11, 0],
        type: "poly"
      };
      return new google.maps.Marker({
        map: this.map,
        position: position,
        icon: icon,
        shadow: shadow,
        shape: shape,
        animation: google.maps.Animation.DROP,
        title: user.get("name")
      });
    };

    EventView.prototype.infoWindowForUser = function(user) {
      var content;

      content = this.nameInfoTemplate({
        user: user
      });
      if (user.get("phone")) {
        content += this.phoneInfoTemplate({
          user: user
        });
      }
      return new google.maps.InfoWindow({
        content: content
      });
    };

    EventView.prototype.onTimeout = function() {
      return navigator.geolocation.getCurrentPosition(this.onLocateSuccess, this.onLocateFailure);
    };

    EventView.prototype.onLocateSuccess = function(position) {
      var user;

      user = App.user();
      user.set({
        latitude: position.coords.latitude,
        longitude: position.coords.longitude
      });
      return user.save(null, {
        success: this.onSaveSuccess,
        error: this.onSaveError
      });
    };

    EventView.prototype.onLocateFailure = function(error) {
      return this.fetchUsers();
    };

    EventView.prototype.onSaveSuccess = function(user, response) {
      console.log("saved");
      return this.fetchUsers();
    };

    EventView.prototype.onSaveError = function(user, response) {
      return this.fetchUsers();
    };

    EventView.prototype.onFetchSuccess = function(users, response) {
      console.log("updated");
      this.updateUsers();
      return setTimeout(this.onTimeout, 5000);
    };

    EventView.prototype.onFetchError = function(users, response) {
      return setTimeout(this.onTimeout, 5000);
    };

    EventView.prototype.onSelectUser = function() {
      return this.openInfoWindow(this.users.get(this.usersSelect.val()));
    };

    EventView.prototype.onClickDetails = function() {
      return this.openInfoWindow(null);
    };

    return EventView;

  })(BaseView);

  GoApp = (function(_super) {
    __extends(GoApp, _super);

    function GoApp() {
      _ref1 = GoApp.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    GoApp.prototype._user = new UserModel(userObj);

    GoApp.prototype._event = new EventModel(eventObj);

    GoApp.prototype.user = function() {
      return this._user;
    };

    GoApp.prototype.event = function() {
      return this._event;
    };

    return GoApp;

  })(BaseApp);

  $(function() {
    window.App = new GoApp();
    return App.activateView(new EventView());
  });

}).call(this);
