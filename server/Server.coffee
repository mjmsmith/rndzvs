argv = require("optimist").default("port", 3000).argv
connectCoffeeScript = require("connect-coffee-script")
express = require("express")
fs = require("fs")
jade = require("jade")
path = require("path")

Db = require("./Db")
Event = Db.Event
User = Db.User

class exports.Server
  
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
  
  loadSessionUser: (req, res, next) ->
    if req.session.userId
      User.findById req.session.userId, (err, user) ->
        if user
          req.user = user
          next()
        else
          res.redirect("/")
    else
      res.redirect("/")

  createServer: ->
    server = express()

    server.configure =>
      server.set("views", path.join(@rootDir(), "views"))
      server.set("view engine", "jade")
      server.use(express.logger({ format: ":method :url :status :response-time ms" }))
      server.use(express.bodyParser())
      server.use(express.methodOverride())
      server.use(express.cookieParser())
      server.use(express.session({ store: Db.sessionDb, secret: "secret", cookie: { maxAge: Server.cookieMaxAge } })) # TODO
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

    server.get "/", (req, res) =>
      console.log req.session
      User.find { _id: { $in: (req.session.userIds || []) } }, (err, users) ->
        Event.find { _id: { $in: (user.event for user in users) } }, (err, events) ->
          res.render("index", {
            events: events
          })

    server.get "/create", (req, res) ->
      res.render("create", {
        title: "rndvz"
      })

    server.get "/join/:code", (req, res) ->
      Event.findOne { code: req.params.code }, (err, event) ->
        if event
          res.render("join", {
            title: "rndvz"
            event: event.toBackboneJSON()
          })
        else
          res.redirect("/")

    server.get "/go/:code", (req, res) ->
      Event.findOne { code: req.params.code }, (err, event) ->
        if event
          if req.session.userIds
            User.findOne { _id: { $in: req.session.userIds }, event: event._id }, (err, user) ->
              if user
                res.render("go", {
                  user: user.toBackboneJSON()
                  event: event.toBackboneJSON()
                  title: event.name
                })
              else
                res.redirect("/join/#{req.params.code}")
          else
            res.redirect("/join/#{req.params.code}")
        else
          res.redirect("/")

    # Event routes.

    server.get "/events", @loadSessionUser, (req, res) ->
      Event.find req.query, (err, events) ->
        res.send(event.toJSON() for event in events)

    server.post "/events", (req, res) ->
      event = new Event(req.body)
      event.save (err, event) ->
        res.send(event.toJSON())

    server.get "/events/:id", (req, res) ->
      Event.findById req.params.id, (err, event) ->
        res.send(event.toJSON())

    server.put "/events/:id", (req, res) ->
      Event.findById req.params.id, (err, event) ->
        event[key] = val for own key, val of req.body
        event.save (err, event) ->
          res.send(event.toJSON())

    server.del "/events/:id", (req, res) ->
      Event.remove { _id: req.params.id }, (err, count) ->
        res.send(JSON.stringify(!err && count == 1))

    # User routes.

    server.get "/users", (req, res) ->
      User.find req.query, (err, users) ->
        res.send(user.toJSON() for user in users)

    server.post "/users", (req, res) ->
      Event.findById req.body.event, (err, event) ->
        user = new User(req.body)
        user.save (err, user) ->
          req.session.userId = user._id.toHexString()
          req.session.userIds = [] if !req.session.userIds
          req.session.userIds.push(req.session.userId)

          if !event.creator
            event.creator = user
            event.save (error, event) ->
              res.send(user.toJSON())
          else
            res.send(user.toJSON())

    server.get "/users/:id", (req, res) ->
      User.findById req.params.id, (err, user) ->
        res.send(user.toJSON())

    server.put "/users/:id", (req, res) ->
      User.findById req.params.id, (err, user) ->
        user[key] = val for own key, val of req.body
        user.save (err, user) ->
          res.send(user.toJSON())

    server.del "/users/:id", (req, res) ->
      User.remove { _id: req.params.id }, (err, count) ->
        req.session.userIds = (id for id in req.session.userIds where id != req.params.id)
        res.send(JSON.stringify(!err && count == 1))

    # Misc routes.

    server.get "/javascripts/client/views/:app.js", (req, res) =>
      res.set("Content-Type", "application/javascript")
      res.send(@_clientTemplates[req.params.app])

    server.listen(argv.port)
    console.log("running on port #{argv.port}...")

    server
