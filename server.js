#!/usr/bin/env node

'use strict';

var fs          = require('fs');
var express 	= require("express");
var app 	= express();
var server	= require('http').createServer(app);
var io          = require('socket.io').listen(server, {log: false});
var mongodb 	= require('mongodb');
var sanitizer   = require('sanitizer');
var _           = require('underscore');
var colors      = require('colors');

// Web Server Configuration
var server_port = parseInt(process.argv[2], 10) || 8080; // most OS's will require sudo to listen on 80
var server_address = '127.0.0.1';

// MongoDB Configuration
var mongo_host = '127.0.0.1';
var mongo_port = 27017;
var mongo_req_auth = false; // Does your MongoDB require authentication?
var mongo_user = 'admin';
var mongo_pass = 'password';
//var mongo_collection = 'startplane';
//var mongo_db = 'tiles';

var mongo_collection = 'tiles';
var mongo_db = 'terraformia';

var mongoServer = new mongodb.Server(mongo_host, mongo_port, {});

var collections = {
    map: undefined
};

function logger(title, message) {
    while (title.length < 26) {
        title = title + ' ';
    }
    console.log(title + message);
}

function initializeTimers() {
    // Initialize timers
    _.each(game.events, function(event) {
        event.handle = setInterval(
            event.payload,
            event.interval
        );
    });
}


// Logic to determine whether a specified connection is allowed.
function connectionIsAllowed(request){
    // Check criteria such as request.origin, request.remoteAddress 
    return true;
}

var game = {
    dirtyBit: false,
    levelName: '1',
     
      // Giant array of map data
      // Make this so its not a giant array of map data.
      
    map: [],
    //corruption_map: [],
    getTileData: function(x, y) {
        var tile = game.map[x][y];
        var data = {};
        if (tile && typeof tile[0] != 'undefined') {
            data.tile = game.descriptors.terrain[tile[0]];
        }
        if (tile && typeof tile[1] != 'undefined') {
            data.health = tile[1];
        }
        return data;
    },
    
      // Data from tilesets JSON
    descriptors: {}
     
};


function buildMap(db) {
    logger("MongoDB".blue, "Attempting to build the database");
    var fileContents = fs.readFileSync('map.json','utf8');
    var mapData = JSON.parse(fileContents);
    db.collection('maps', function(err, collection) {
        logger("MongoDB".blue, "Connecting to the map collection");
        if (err) {
            logger("Error".red, err);
            throw err;
        }
        logger("MongoDB".blue, "Cool, I connected to the collection");
        collection.remove({}, function(err, result) {
            logger("MongoDB".blue, "Removing the entries from the collection");
            collection.insert({map: mapData, levelName: game.levelName});
            collection.count(function(err, count) {
                logger("MongoDB".blue, "Done counting, not sure what I found");
                if (count == 1) {
                    game.map = mapData;
                    logger("MongoDB".blue, "Map was rebuilt from map.json file");
                }
            });
        });
    });
}

new mongodb.Db(mongo_collection, mongoServer, {safe:false}).open(function(err, db) {
	if (err) throw err;

    // indexing query


    var runGame = function() {
        fs.readFile('assets/tilesets/data.json', function(err, data) {
            if (err) throw err;
            game.descriptors = JSON.parse(data);
            setTimeout(function() {
                var remaining = 80;
                var coords = {};
                while (remaining) {
                    coords.x = Math.floor(Math.random() * 199);
                    coords.y = Math.floor(Math.random() * 199);
                    remaining--;
                }
            }, 1000);
        });

        // Every minute we want to write the database from memory to mongo
        setInterval(function() {
            if ( game.dirtyBit ) {
                db.collection('tiles', function(err, collection) {
                    if (err) {
                        logger("MongoDB".red, "Error selecting map collection to save", err);
                    }

                    collection.update({levelName: game.levelName}, {$set: {map: game.map}}, function(err, result) {
                        logger("MongoDB".green, "Yo dawg, I hear you like to save maps to the db.");
                        game.dirtyBit = false;
                    });
                });
            }
        }, 5000); // Save map to Mongo once every minute

        logger("Express".magenta, "Attempting to listen on: " + server_address + ':' + server_port);

        server.listen(server_port, server_address);
        app.on('error', function (e) {
            if (e.code == 'EADDRINUSE') {
                logger("Express".red, "Address in use, trying again...");
                setTimeout(function () {
                    app.close();
                    app.listen(server_port, server_address);
                }, 1000);
            } else if (e.code == 'EACCES') {
                logger("Express".red, "You don't have permissions to bind to this address. Try running via sudo.");
            } else {
                logger("Express".red, e);
            }
        });

        // User requests root, return HTML
        app.get('/', function (req, res) {
            res.sendfile(__dirname + '/index.html');
        });
        
         // User requests root, return HTML
        app.get('/styles.css', function (req, res) {
            res.sendfile(__dirname + '/styles.css');
        });


        // User request map, return map JSON from RAM
        app.get('/map', function(req, res) {
            res.send(game.map);
        });

        // User requests map builder page, builds map from JSON file, returns OK
        app.get('/build-map', function(req, res) {
            buildMap(mongoServer);
            res.send("Rebuilt Map");
        });

        // Exports the map from the database to JSON
        app.get('/export-map', function(req, res) {
            db.collection('tiles', function(err, collection) {
                if (err) {
                    res.send(err);
                    throw err;
                }
                collection.findOne({}, {}, function(err, item) {
                    if (err) {
                        res.send(err);
                        throw err;
                    }
                    if (item != null) {
                        var data = JSON.stringify(item.map);
                        fs.writeFileSync('map-export.json', data, 'utf8');
                        res.send("Backed up map");
                        return;
                    } else {
                        res.send("Couldn't back up map");
                        return;
                    }
                });

            });
        });

        // User requests a file in the assets folder, read it and return it
       
     
         app.get('/images/*', function (req, res) {
            // is this secure? in PHP land it would be pretty bad
            res.sendfile(__dirname + '/images/' + req.params[0] );
        });
        
        app.get('/js/*', function (req, res) {
            res.sendfile(__dirname + '/js/' + req.params[0] );
        });
        
         app.get('/images/aircraft/*', function (req, res) {
            res.sendfile(__dirname + '/images/aircraft/' + req.params[0] );
        });
        
         app.get('/images/buildings/*', function (req, res) {
            res.sendfile(__dirname + '/images/buildings/' + req.params[0] );
        });
        
        
          app.get('/images/bullets/*', function (req, res) {
            res.sendfile(__dirname + '/images/bullets/' + req.params[0] );
        });
        
          app.get('/images/characters/*', function (req, res) {
            res.sendfile(__dirname + '/images/characters/' + req.params[0] );
        });
        
         app.get('/images/maps/*', function (req, res) {
            res.sendfile(__dirname + '/images/maps/' + req.params[0] );
        });
        
         app.get('/images/terrian/*', function (req, res) {
            res.sendfile(__dirname + '/images/terrian/' + req.params[0] );
        });
        
         app.get('/audio/*', function (req, res) {
            res.sendfile(__dirname + '/audio/' + req.params[0] );
        });
         app.get('/images/vehicles/*', function (req, res) {
            res.sendfile(__dirname + '/images/vehicles/' + req.params[0] );
        });

           app.get('/assets/tilesets/*', function (req, res) {
            res.sendfile(__dirname + '/assets/tilesets/' + req.params[0] );
        });


var mymap = new Array(64);
  for (var i = 0; i < 64; i++) {
    mymap[i] = new Array(64);
  }


  for (var j = 64 - 1; j >= 0; j--){
        for (var i = 64 - 1; i >= 0; i--){
        if(!mymap[j][i]){
            mymap[j][i] = [0,null];
           }
        }
       } 

        // Builds the map object with data from the mongo db
      
     db.collection('tiles', function(err, collection) {
            if (err) {
                logger("MongoDB".red, "Map collection doesn't exist", err);
                throw err;
            }
           
          
          collection.find( { position : { 
             								$geoWithin : { 
             								$box : [ [ 0 , 0 ] , [ 63 , 63 ] ] }}}, {collide: 0, _id: 0} ).each(function(err, results)  {       
               if (results != null) {
                  
                 
                  
                 mymap[results.position.x][results.position.y] = [results.type,null];
                
                    return;
               } 
        });
            
     
      //Fill in blanks
   
       game.map = mymap;
		
            
        });
    };

    if (mongo_req_auth) {
        mongoServer.uthenticate(mongo_user, mongo_pass, function(err, data) {
            runGame();
        });
    } else {
        runGame();
    }
});
