///<reference path='../d.ts/DefinitelyTyped/express/express.d.ts'/>

var Express = require("express");
var Mongoose =  require("mongoose");
var MongoStore = require("connect-mongo")(Express);

var Schema = Mongoose.Schema;
var ObjectId = Schema.ObjectId;

// Events.

var EventSchema = new Schema({
  createdAt: {
    type: Date,
    default: function() { return new Date(); }
  },
  code: {
    type: String,
    default: function() {
      var code = "";
      for (var i = 0; i < 10; ++i) {
        code += "abcdefghjkmnpqrstuvwxyz23456789"[Math.floor(Math.random()*31)];
      }
      return code;
    },
    unique: true
  },
  name: String,
  info: String,
  place: String,
  address: String,
  latitude: Number,
  longitude: Number,
  date: Date,
  creator: ObjectId
});

EventSchema.methods.toBackboneJSON = function() {
  var json = this.toJSON();
  json.id = json._id;
  delete json._id;
  return json;
};

export var Event = Mongoose.model("Event", EventSchema);

// Users.

var UserSchema = new Schema({
  createdAt: {
    type: Date,
    default: function() { return new Date(); }
  },
  updatedAt: Date,
  name: String,
  phone: String,
  event: ObjectId,
  latitude: Number,
  longitude: Number
});

UserSchema.methods.toBackboneJSON = function() {
  var json = this.toJSON();
  json.id = json._id;
  delete json._id;
  return json;
};

UserSchema.pre('save', function(next) {
  this.updatedAt = this.updatedAt ? new Date() : this.createdAt;
  next()
});
  
export var User = Mongoose.model("User", UserSchema);

export var appDb = Mongoose.connect("mongodb://localhost/rndzvs");
export var sessionDb = new MongoStore({ db: "rndzvs" });
