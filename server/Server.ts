///<reference path='../d.ts/DefinitelyTyped/express/express.d.ts'/>

var fs = require("fs"); 
var path = require("path");
var util = require("util");

var optimist = require("optimist");
var connectCoffeeScript = require("connect-coffee-script");
var express = require("express");
var jade = require("jade");
var stylus = require("stylus");

var Db = require("./Db");
var Event = Db.Event;
var User = Db.User;

interface ExpressSession {
  userId: string;
  userIds: string[];
}

export class Server
{
  static cookieMaxAge: number = 10*24*60*60*1000;

  _server: Express = null;
  _rootDir: string = null;
  _clientTemplates = {};

  // Public.

  constructor(rootDir: string) {
    var apps: string[] = <string[]>fs.readdirSync(path.join(rootDir, "client", "views")).filter(function(file) {
      return fs.statSync(path.join(rootDir, "client", "views", file)).isDirectory();
    });

    this._rootDir = rootDir;
    
    apps.forEach((app) => {
      this._clientTemplates[app] = this.compileClientAppTemplates(path.join(rootDir, "client", "views", app));
    });
    
    this._server = this.createServer();
  }
  
  public server() {
    return this._server;
  }
    
  public rootDir() {
    return this._rootDir;
  }

  // Private.

  private compileClientAppTemplates(dir: string): string {
    var js = "";
    var files = fs.readdirSync(dir).filter((file: string) => { return file.substr(-5) === ".jade"; });

    files.forEach((file: string) => {
      var view = file.substr(0, file.indexOf("."));
      var filePath = path.join(dir, file);
      var options = { debug: false, client: true, filename: filePath };
      var fileContents = fs.readFileSync(filePath, "utf8").toString();
      var parts = fileContents.split(new RegExp("^[/][/]-\\W?([^.]+)[.]jade$", "mg"));
      
      parts.unshift(view);

      for (var i = 0; i < parts.length; i += 2) {
        js += util.format("%s: %s,\n", parts[i], jade.compile(parts[i+1], options));
      }
    });
      
    return util.format("Templates = {\n%s\n};", js);
  }
  
  private static loadSessionUser(req: ExpressServerRequest, res: ExpressServerResponse, next) {
    if ((<any>req.session).userId) {
      User.findById((<any>req.session).userId, function(err, user) {
        if (user) {
          req.user = user;
          next();
        }
        else {
          res.redirect("/");
        }
      });
    }  
    else {
      res.redirect("/");
    }
  }
  
  private createServer() {
    var server: Express = express();
    
    server.configure(() => {
      server.set("views", path.join(this.rootDir(), "views"));
      server.set("view engine", "jade");
      server.use(express.logger({ format: ":method :url :status :response-time ms" }));
      server.use(express.bodyParser());
      server.use(express.methodOverride());
      server.use(express.cookieParser());
      server.use(express.session({ store: Db.sessionDb, secret: "secret", cookie: { maxAge: Server.cookieMaxAge } })); // TODO
      server.use(stylus.middleware({ src: path.join(this.rootDir(), "public") }));
      server.use(connectCoffeeScript({
        src: this.rootDir(),
        dest: path.join(this.rootDir(), "public", "javascripts"),
        prefix: "/javascripts"
      }));
      server.use(express.static(path.join(this.rootDir(), "public")));
      server.use(server.router);
    });

    server.configure("development", function() {
      server.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
    });
    
    server.configure("production", function() {
      server.use(express.errorHandler());
     });
    
    // Routes.
  
    server.get("/", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      User.find({ _id: { $in: ((<any>req.session).userIds ? (<any>req.session).userIds : []) } }, function(err, users) : void {
        Event.find({ _id: { $in: (users.map(function(user) { return user.event; })) } }, function(err, events) {
          res.render("index", {
            events: events
          });
        });
      });
    });
      
    server.get("/create", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      res.render("create", {
        title: "rndvz"
      });
    });

    server.get("/join/:code", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      Event.findOne({ code: req.params.code }, function(err, event) {
        if (event) {
          res.render("join", {
            title: "rndvz",
            event: event.toBackboneJSON()
          });
        }
        else {
          res.redirect("/");
        }
      });
    });

    server.get("/go/:code", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      Event.findOne({ code: req.params.code }, function(err, event) {
        if (event) {
          if ((<any>req.session).userIds) {
            User.findOne({ _id: { $in: (<any>req.session).userIds }, event: event._id }, function(err, user) : void {
              if (user) {
                res.render("go", {
                  user: user.toBackboneJSON(),
                  event: event.toBackboneJSON(),
                  title: event.name
                });
              }
              else {
                res.redirect(util.format("/join/%s", req.params.code));
              }
            });
          }
          else {
            res.redirect(util.format("/join/%s", req.params["code"]));
          }
        }
        else {
          res.redirect("/");
        }
      });
    });
    
    // Event routes.

    server.get("/events", Server.loadSessionUser, function(req: ExpressServerRequest, res: ExpressServerResponse) {
      Event.find(req.query, function(err, events) {
        res.send(events.map(function(event) { return event.toJSON() }));
      });
    });

    server.post("/events", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      var event = new Event(req.body);
      event.save(function(err, event) {
        res.send(event.toJSON());
      });
    });

    server.get("/events/:id", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      Event.findById(req.params.id, function(err, event) {
        res.send(event.toJSON());
      });
    });
     

    server.put("/events/:id", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      Event.findById(req.params.id, function(err, event) {
        Object.keys(req.body).forEach(function(key) {
          event[key] = req.body[key];
        });
        event.save(function(err, event) {
          res.send(event.toJSON());
        });
      });
    });

    server.del("/events/:id", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      Event.remove({ _id: req.params.id }, function(err, count) {
        res.send(JSON.stringify((!err && count === 1)));
      });
    });

    // User routes.

    server.get("/users", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      User.find(req.query, function(err, users) {
        res.send(users.map(function(user) { return user.toJSON() }));
      });
    });

    server.post("/users", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      Event.findById(req.body["event"], function(err, event) {
        var user = new User(req.body);
        user.save(function(err, user) {
          (<any>req.session).userId = user._id.toString();
          if (!(<any>req.session).userIds) {
            (<any>req.session).userIds = [];
          }
          (<any>req.session).userIds.push((<any>req.session).userId);

          if (!event.creator) {
            event.creator = user;
            event.save(function(error, event) {
              res.send(user.toJSON());
            });
          }
          else {
            res.send(user.toJSON());
          }
        });
      });
    });

    server.get("/users/:id", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      User.findById(req.params.id, function(err, user) {
        res.send(user.toJSON());
      });
    });

    server.put("/users/:id", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      User.findById(req.params.id, function(err, user) {
        Object.keys(req.body).forEach(function(key) {
          user[key] = req.body[key];
        });
        user.save(function(err, user) {
          res.send(user.toJSON());
        });
      });
    });

    server.del("/users/:id", function(req: ExpressServerRequest, res: ExpressServerResponse) {
      User.remove({ _id: req.params.id }, function(err, count) {
        (<any>req.session).userIds = <string[]>(<any>req.session).userIds.filter(function(id) { return id != req.params.id; });
        res.send(JSON.stringify(<any>(!err && count === 1)));
      });
    });

    // Misc routes.

    server.get("/javascripts/client/views/:app.js", (req: ExpressServerRequest, res: ExpressServerResponse) => {
      res.set("Content-Type", "application/javascript");
      res.send(this._clientTemplates[req.params["app"]]);
    });

    var port = optimist.default("port", 3000).argv["port"];

    server.listen(port);
    console.log(util.format("running on port %d...", port));

    return server;
  }
}
