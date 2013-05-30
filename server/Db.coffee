Express = require("express")
Mongoose = require("mongoose")
MongoStore = require("connect-mongo")(Express)

Schema = Mongoose.Schema
ObjectId = Schema.ObjectId

# Events.

EventSchema = new Schema({
  createdAt: {
    type: Date
    "default": -> new Date()
  }
  code: {
    type: String
    "default": -> ("abcdefghjkmnpqrstuvwxyz23456789"[Math.floor(Math.random()*31)] for i in [0..10]).join("")
    unique: true
  }
  name: String
  info: String
  place: String
  address: String
  latitude: Number
  longitude: Number
  date: Date
  creator: ObjectId
})

EventSchema.methods.toBackboneJSON = () ->
  json = @toJSON()
  json.id = json._id
  delete json._id
  json

exports.Event = Mongoose.model("Event", EventSchema)

# Users.

UserSchema = new Schema({
  createdAt: {
    type: Date
    "default": -> new Date()
  }
  updatedAt: Date
  name: String
  phone: String
  event: ObjectId
  latitude: Number
  longitude: Number
})

UserSchema.methods.toBackboneJSON = () ->
  json = @toJSON()
  json.id = json._id
  delete json._id
  json

UserSchema.pre 'save', (next) ->
  @updatedAt = if !@updatedAt then @createdAt else new Date()
  next()

exports.User = Mongoose.model("User", UserSchema)

exports.appDb = Mongoose.connect("mongodb://localhost/rndzvs")
exports.sessionDb = new MongoStore(db: "rndzvs")
