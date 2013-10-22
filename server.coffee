
# Web Server Configuration
# most OS's will require sudo to listen on 80

# MongoDB Configuration
# Does your MongoDB require authentication?

#var mongo_collection = 'startplane';
#var mongo_db = 'tiles';
logger = (title, message) ->
  title = title + " "  while title.length < 26
  console.log title + message
initializeTimers = ->
  
  # Initialize timers
  _.each game.events, (event) ->
    event.handle = setInterval(event.payload, event.interval)


# Logic to determine whether a specified connection is allowed.
connectionIsAllowed = (request) ->
  
  # Check criteria such as request.origin, request.remoteAddress 
  true

# Giant array of map data
# Make this so its not a giant array of map data.

#corruption_map: [],

# Data from tilesets JSON
buildMap = (db) ->
  logger "MongoDB".blue, "Attempting to build the database"
  fileContents = fs.readFileSync("map.json", "utf8")
  mapData = JSON.parse(fileContents)
  db.collection "maps", (err, collection) ->
    logger "MongoDB".blue, "Connecting to the map collection"
    if err
      logger "Error".red, err
      throw err
    logger "MongoDB".blue, "Cool, I connected to the collection"
    collection.remove {}, (err, result) ->
      logger "MongoDB".blue, "Removing the entries from the collection"
      collection.insert
        map: mapData
        levelName: game.levelName

      collection.count (err, count) ->
        logger "MongoDB".blue, "Done counting, not sure what I found"
        if count is 1
          game.map = mapData
          logger "MongoDB".blue, "Map was rebuilt from map.json file"



"use strict"
fs = require("fs")
express = require("express")
app = express()
server = require("http").createServer(app)
io = require("socket.io").listen(server,
  log: false
)
mongodb = require("mongodb")
sanitizer = require("sanitizer")
_ = require("underscore")
colors = require("colors")
server_port = parseInt(process.argv[2], 10) or 8080
server_address = "127.0.0.1"
mongo_host = "127.0.0.1"
mongo_port = 27017
mongo_req_auth = false
mongo_user = "admin"
mongo_pass = "password"
mongo_collection = "tiles"
mongo_db = "terraformia"
mongoServer = new mongodb.Server(mongo_host, mongo_port, {})
collections = map: `undefined`
game =
  dirtyBit: false
  levelName: "1"
  map: []
  getTileData: (x, y) ->
    tile = game.map[x][y]
    data = {}
    data.tile = game.descriptors.terrain[tile[0]]  if tile and typeof tile[0] isnt "undefined"
    data.health = tile[1]  if tile and typeof tile[1] isnt "undefined"
    data

  descriptors: {}

new mongodb.Db(mongo_collection, mongoServer,
  safe: false
).open (err, db) ->
  throw err  if err
  
  # indexing query
  runGame = ->
    fs.readFile "assets/tilesets/data.json", (err, data) ->
      throw err  if err
      game.descriptors = JSON.parse(data)
      setTimeout (->
        remaining = 80
        coords = {}
        while remaining
          coords.x = Math.floor(Math.random() * 199)
          coords.y = Math.floor(Math.random() * 199)
          remaining--
      ), 1000

    
    # Every minute we want to write the database from memory to mongo
    setInterval (->
      if game.dirtyBit
        db.collection "tiles", (err, collection) ->
          logger "MongoDB".red, "Error selecting map collection to save", err  if err
          collection.update
            levelName: game.levelName
          ,
            $set:
              map: game.map
          , (err, result) ->
            logger "MongoDB".green, "Yo dawg, I hear you like to save maps to the db."
            game.dirtyBit = false


    ), 5000 # Save map to Mongo once every minute
    logger "Express".magenta, "Attempting to listen on: " + server_address + ":" + server_port
    server.listen server_port, server_address
    app.on "error", (e) ->
      if e.code is "EADDRINUSE"
        logger "Express".red, "Address in use, trying again..."
        setTimeout (->
          app.close()
          app.listen server_port, server_address
        ), 1000
      else if e.code is "EACCES"
        logger "Express".red, "You don't have permissions to bind to this address. Try running via sudo."
      else
        logger "Express".red, e

    
    # User requests root, return HTML
    app.get "/", (req, res) ->
      res.sendfile __dirname + "/index.html"

    
    # User requests root, return HTML
    app.get "/styles.css", (req, res) ->
      res.sendfile __dirname + "/styles.css"

    
    # User request map, return map JSON from RAM
    app.get "/map", (req, res) ->
      res.send game.map

    
    # User requests map builder page, builds map from JSON file, returns OK
    app.get "/build-map", (req, res) ->
      buildMap mongoServer
      res.send "Rebuilt Map"

    
    # Exports the map from the database to JSON
    app.get "/export-map", (req, res) ->
      db.collection "tiles", (err, collection) ->
        if err
          res.send err
          throw err
        collection.findOne {}, {}, (err, item) ->
          if err
            res.send err
            throw err
          if item?
            data = JSON.stringify(item.map)
            fs.writeFileSync "map-export.json", data, "utf8"
            res.send "Backed up map"
            return
          else
            res.send "Couldn't back up map"
            return



    
    # User requests a file in the assets folder, read it and return it
    app.get "/images/*", (req, res) ->
      
      # is this secure? in PHP land it would be pretty bad
      res.sendfile __dirname + "/images/" + req.params[0]

    app.get "/js/*", (req, res) ->
      res.sendfile __dirname + "/js/" + req.params[0]

    app.get "/images/aircraft/*", (req, res) ->
      res.sendfile __dirname + "/images/aircraft/" + req.params[0]

    app.get "/images/buildings/*", (req, res) ->
      res.sendfile __dirname + "/images/buildings/" + req.params[0]

    app.get "/images/bullets/*", (req, res) ->
      res.sendfile __dirname + "/images/bullets/" + req.params[0]

    app.get "/images/characters/*", (req, res) ->
      res.sendfile __dirname + "/images/characters/" + req.params[0]

    app.get "/images/maps/*", (req, res) ->
      res.sendfile __dirname + "/images/maps/" + req.params[0]

    app.get "/images/terrian/*", (req, res) ->
      res.sendfile __dirname + "/images/terrian/" + req.params[0]

    app.get "/audio/*", (req, res) ->
      res.sendfile __dirname + "/audio/" + req.params[0]

    app.get "/images/vehicles/*", (req, res) ->
      res.sendfile __dirname + "/images/vehicles/" + req.params[0]

    app.get "/assets/tilesets/*", (req, res) ->
      res.sendfile __dirname + "/assets/tilesets/" + req.params[0]

    mymap = new Array(64)
    i = 0

    while i < 64
      mymap[i] = new Array(64)
      i++
    j = 64 - 1

    while j >= 0
      i = 64 - 1

      while i >= 0
        mymap[j][i] = [0, null]  unless mymap[j][i]
        i--
      j--
    
    # Builds the map object with data from the mongo db
    db.collection "tiles", (err, collection) ->
      if err
        logger "MongoDB".red, "Map collection doesn't exist", err
        throw err
      collection.find(
        position:
          $geoWithin:
            $box: [[0, 0], [63, 63]]
      ,
        collide: 0
        _id: 0
      ).each (err, results) ->
        if results?
          mymap[results.position.x][results.position.y] = [results.type, null]
          return

      
      #Fill in blanks
      game.map = mymap


  if mongo_req_auth
    mongoServer.uthenticate mongo_user, mongo_pass, (err, data) ->
      runGame()

  else
    runGame()

