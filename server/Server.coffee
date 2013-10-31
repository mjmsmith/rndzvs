argv = require("optimist").default("port", 3000).argv
connectCoffeeScript = require("connect-coffee-script")
connectMySqlSession = require("connect-mysql-session")
express = require("express")
fs = require("fs")
jade = require("jade")
path = require("path")
db = require("./db")

Event = db.Event
User = db.User
MySqlSessionStore = connectMySqlSession(express)

class Server
  
  @cookieMaxAge: 10*24*60*60*1000

  _server: null
  _rootDir: null
  _clientTemplates: {}

  # Public.

  constructor: (rootDir) ->
    apps = fs.readdirSync(path.join(rootDir, "client", "views")).filter (file) ->
      fs.statSync(path.join(rootDir, "client", "views", file)).isDirectory()

    @_rootDir = rootDir
    @_clientTemplates[app] = @compileClientAppTemplates(path.join(rootDir, "client", "views", app)) for app in apps
    @_server = @createServer()

  server: () ->
    @_server

  rootDir: () ->
    @_rootDir

  # Private.

  compileClientAppTemplates: (dir) ->
    js = ""
    files = fs.readdirSync(dir).filter (file) -> file.substr(-5) == ".jade"

    for file in files
      view = file.substr(0, file.indexOf("."))
      filePath = path.join(dir, file)
      fileContents = fs.readFileSync(filePath, "utf8")
      parts = fileContents.split(/^[/][/]-\W?([^.]+)[.]jade$/mg)
      parts.unshift(view)

      i = 0
      while i < parts.length
        options = { debug: false, client: true, filename: filePath }
        js += "#{parts[i++]}: #{jade.compile(parts[i++], options)},\n"

    "Templates = {\n#{js}\n};"
  
  loadSessionUser: (req, res, next) =>
    if req.session.activeUserId
      new User(id: req.session.activeUserId).fetch().then(
        (user) ->
          req.user = user
          next()
        ,
        () ->
          res.redirect("/")
      )
    else
      res.redirect("/")

  requireDevEnv: (req, res, next) =>
    if process.env.NODE_ENV == "development"
      next()
    else
      res.send(401, "no");

  createServer: ->
    server = express()

    server.configure =>
      server.set("views", path.join(@rootDir(), "views"))
      server.set("view engine", "jade")
      server.use(express.logger({ format: ":method :url :status :response-time ms" }))
      server.use(express.bodyParser())
      server.use(express.methodOverride())
      server.use(express.cookieParser())
      server.use(express.session({
                                    store: new MySqlSessionStore("rndzvs", process.env.MYSQL_USER, process.env.MYSQL_PASSWORD, {})
                                    secret: "secret"
                                    cookie: { maxAge: Server.cookieMaxAge }
                                  }))
      server.use(require("stylus").middleware({ src: path.join(@rootDir(), "public") }))
      server.use(connectCoffeeScript({
        src: @rootDir()
        dest: path.join(@rootDir(), "public", "javascripts")
        prefix: "/javascripts"
      }))
      server.use(express.static(path.join(@rootDir(), "public")))
      server.use(server.router)

    server.configure "development", =>
      server.use(express.errorHandler({ dumpExceptions: true, showStack: true }))

    server.configure "production", =>
      server.use(express.errorHandler())

    # Routes.

    server.get "/", (req, res) ->
      userIds = if req.session.userIds?.length > 0 then req.session.userIds else [0]

      new User().query().whereIn("id", userIds).then (users) ->
        users = User.toModels(users)
        eventIds = if users.length > 0 then user.eventId for user in users else [0]

        new Event().query().whereIn("id", eventIds).then (events) ->
          events = Event.toModels(events)
          res.render "index", {
            events: events
          }

    server.get "/create", (req, res) ->
      res.render "create", {
        title: "rndvz"
      }

    server.get "/join/:code", (req, res) ->
      new Event(code: req.params.code).fetch().then(
        (event) ->
          res.render "join", {
            title: "rndzvs"
            event: event
          }
        ,
        () ->
          res.redirect("/")
      )
    
    server.get "/go/:code", (req, res) ->
      new Event(code: req.params.code).fetch().then(
        (event) ->
          userIds = if req.session.userIds?.length > 0 then req.session.userIds else [0]
          new User().query().where(eventId: event.id).whereIn("id", userIds).then(
            (users) ->
              users = User.toModels(users)
              if users.length == 1
                req.session.activeUserId = users[0].id
                res.render "go", {
                  title: event.name
                  user: users[0]
                  event: event
                }
              else
                res.redirect("/join/#{req.params.code}")
            ,
            () ->          
              res.redirect("/")
          )
        ,
        () ->
          res.redirect("/")
      )

    # Event routes.

    server.get "/events", @requireDevEnv, (req, res) ->
      new Event().query().then (events) ->
        events = Event.toModels(events)
        res.send(event.toJSON() for event in events)

    server.post "/events", (req, res) ->
      new Event(req.body).save().then (event) ->
        res.send(event.toJSON())

    server.get "/events/:id", (req, res) ->
      new Event(id: req.params.id).fetch().then (event) ->
        res.send(event.toJSON())

    server.put "/events/:id", @requireDevEnv, (req, res) ->
      new Event(id: req.params.id).fetch().then (event) ->
        event.set(req.body)
        event.save().then (event) ->
          res.send(event.toJSON())

    server.del "/events/:id", @requireDevEnv, (req, res) ->
      new Event(id: req.params.id).destroy()
      res.send(JSON.stringify(true))

    # User routes.

    server.get "/users", @loadSessionUser, (req, res) ->
      new User().query().where(eventId: req.user.eventId).then(
        (users) ->
          users = User.toModels(users)
          res.send(user.toJSON() for user in users)
        ,
        (err) ->
          console.log(err)
          res.send(500, "no");
      )

    server.post "/users", (req, res) ->
      new Event(id: req.body.eventId).fetch().then (event) ->
        new User(req.body).save().then (user) ->
          req.session.activeUserId = user.id
          req.session.userIds = [] if !req.session.userIds
          req.session.userIds.push(req.session.activeUserId)

          if !event.creatorId
            event.creatorId = user.id
            event.save().then (event) ->
              res.send(user.toJSON())
          else
            res.send(user.toJSON())

    server.get "/users/:id", (req, res) ->
      new User(id: req.params.id).fetch().then (user) ->
        res.send(user.toJSON())

    server.put "/users/:id", @loadSessionUser, (req, res) ->
      req.user.set(req.body)
      req.user.save().then (user) ->
        res.send(user.toJSON())

    server.del "/users/:id", @requireDevEnv, (req, res) ->
      new User(id: req.params.id).destroy()
      req.session.userIds = (id for id in req.session.userIds if id != req.params.id)
      res.send(JSON.stringify(true))

    # Misc routes.

    server.get "/javascripts/client/views/:app.js", (req, res) =>
      res.set("Content-Type", "application/javascript")
      res.send(@_clientTemplates[req.params.app])

    server.listen(argv.port)
    console.log("running on port #{argv.port}...")

    return server

  module.exports = Server
