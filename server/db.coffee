express = require("express")
bookshelf = require("bookshelf")

MySql = bookshelf.initialize {
  client: "mysql"
  connection: {
    host: "127.0.0.1"
    user: process.env.MYSQL_USER
    password: process.env.MYSQL_PASSWORD
    database: "rndzvs"
    charset: "utf8"
    #debug: "true"
  }
}

# Model.

class RndzvsModel extends MySql.Model

  toString: () ->
    @constructor.name

class RndzvsCollection extends MySql.Collection

  toString: () ->
    @constructor.name

# Event.

class Event extends RndzvsModel

  tableName: "event"

  @defineProperty: (prop) ->
    Object.defineProperty @prototype, prop, {
      get: () -> @get(prop)
      set: (value) -> @set(prop, value)
    }

  for prop in ["createdAt", "code", "name", "info", "place", "address", "latitude", "longitude", "date", "creatorId"]
    @defineProperty(prop)

  @toModel: (obj) ->
    return new Event(obj)

  @toModels: (objs) ->
    return (new Event(obj) for obj in objs)

  constructor: (attrs, opts) ->
    super

    @on "saving", (event, attrs, opts) ->
      if event.isNew()
        event.code = ("abcdefghjkmnpqrstuvwxyz23456789"[Math.floor(Math.random()*31)] for i in [0..10]).join("")
        event.createdAt = new Date()

  users: () ->
    return @hasMany(User, "eventId")

  creator: () ->
    return @belongsTo(User, "creatorId")

class EventCollection extends RndzvsCollection

  model: Event

# User.

class User extends RndzvsModel

  tableName: "user"

  @defineProperty: (prop) ->
    Object.defineProperty @prototype, prop, {
      get: () -> @get(prop)
      set: (value) -> @set(prop, value)
    }

  for prop in ["createdAt", "updatedAt", "name", "phone", "eventId", "latitude", "longitude"]
    @defineProperty(prop)

  @toModel: (obj) ->
    return new User(obj)

  @toModels: (objs) ->
    return (new User(obj) for obj in objs)

  constructor: (attrs, opts) ->
    super

    @on "saving", (user, attrs, opts) ->
      user.updatedAt = new Date()
      user.createdAt = user.updatedAt if user.isNew()

  event: () ->
    return @belongsTo(Event, "eventId")

class UserCollection extends RndzvsCollection

  model: User

module.exports = {
  User
  UserCollection
  Event
  EventCollection
}
