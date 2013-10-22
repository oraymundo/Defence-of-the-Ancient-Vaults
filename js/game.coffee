$(window).load ->
  game.downloadAssets()

game =
  
  # Start preloading assets
  init: ->
    loader.init()
    mouse.init()
    sidebar.init()
    sounds.init()
    $(".gamelayer").hide()
    $("#gamestartscreen").show()
    game.backgroundCanvas = document.getElementById("gamebackgroundcanvas")
    game.backgroundContext = game.backgroundCanvas.getContext("2d")
    game.foregroundCanvas = document.getElementById("gameforegroundcanvas")
    game.foregroundContext = game.foregroundCanvas.getContext("2d")
    game.canvasWidth = game.backgroundCanvas.width
    game.canvasHeight = game.backgroundCanvas.height
    game.graphics.initialize()
    game.graphics.viewport.update()
    game.graphics.startAnimation()

  
  # game.map.render();
  downloadAssets: ->
    $.when(game.graphics.tilesets.download("/assets/tilesets/inventory-32x32.png", game.graphics.tilesets.inventory), game.graphics.tilesets.download("/assets/tilesets/monsters-32x32.png", game.graphics.tilesets.monsters), game.graphics.tilesets.download("/assets/tilesets/characters-32x48.png", game.graphics.tilesets.characters), game.graphics.tilesets.download("/assets/tilesets/terrain-32x32.png", game.graphics.tilesets.terrain), game.downloadTiles(), game.downloadMap()).done ->
      game.init()


  graphics:
    TILE_WIDTH_PIXEL: 32
    TILE_HEIGHT_PIXEL: 32
    globalAnimationFrame: false
    selfAnimationFrame: false
    $canvas: null
    handle: null
    initialize: ->
      
      # this view is made for the whole screen!!!
      #Need to change z value on this.
      view = game.graphics.viewport
      view.WIDTH_TILE = Math.floor($(window).width() / game.graphics.TILE_WIDTH_PIXEL)
      view.HEIGHT_TILE = Math.floor($(window).height() / game.graphics.TILE_HEIGHT_PIXEL)
      view.WIDTH_PIXEL = game.graphics.viewport.WIDTH_TILE * game.graphics.TILE_WIDTH_PIXEL
      view.HEIGHT_PIXEL = game.graphics.viewport.HEIGHT_TILE * game.graphics.TILE_HEIGHT_PIXEL
      view.PLAYER_OFFSET_TOP_TILE = Math.floor(view.HEIGHT_TILE / 2)
      view.PLAYER_OFFSET_LEFT_TILE = Math.floor(view.WIDTH_TILE / 2) + 1
      game.graphics.handle = document.getElementById("gamebackgroundcanvas").getContext("2d")

    startAnimation: ->
      
      # Tried using requestAnimationFrame, but that is slow and choppy
      currentFrame = 0
      setInterval (->
        currentFrame++
        if currentFrame % 3 is 0
          currentFrame = 0
          
          # redraw every 150 ms, but change animation every 450 ms
          game.graphics.globalAnimationFrame = not game.graphics.globalAnimationFrame
        
        #game.player.killIfNpcNearby();
        game.map.render currentFrame is 0
      ), 150

    viewport:
      update: ->
        game.graphics.viewport.x = 32
        game.graphics.viewport.y = 32

      WIDTH_PIXEL: null
      HEIGHT_PIXEL: null
      WIDTH_TILE: null
      HEIGHT_TILE: null
      PLAYER_OFFSET_LEFT_TILE: null
      PLAYER_OFFSET_TOP_TILE: null
      x: null
      y: null

    tilesets:
      terrain: new Image()
      characters: new Image()
      monsters: new Image()
      inventory: new Image()
      descriptors:
        terrain: null
        characters: null
        monsters: null
        inventory: null

      download: (url, tileset) ->
        d = $.Deferred()
        tileset.src = url
        tileset.onload = ->
          d.resolve()

        tileset.onerror = ->
          d.reject()

        d.promise()

    
    # Nametags are displayed in HTML in a layer above canvas
    nametags:
      $tags: $("#nametags")
      
      # adds a player name, provided the X and Y coords of the player
      add: (name, x, y, monster) ->
        cls = ""
        cls = " class=\"monster\""  if monster
        x_pixel = (x - 2) * game.graphics.TILE_WIDTH_PIXEL
        y_pixel = (y + 1) * game.graphics.TILE_HEIGHT_PIXEL
        $tags = game.graphics.nametags.$tags
        $name = $("<div class=\"name\"><span" + cls + ">" + name + "</span></div>")
        $name.css
          left: x_pixel
          top: y_pixel

        $tags.append $name

      
      # hide (for efficient DOM redraws) and clear entries
      hide: ->
        game.graphics.nametags.$tags.hide().empty()

      
      # show list again
      show: ->
        game.graphics.nametags.$tags.show()

    drawAvatar: (x, y, tile_x, tile_y, tileset) ->
      x_pixel = x * game.graphics.TILE_WIDTH_PIXEL
      y_pixel = y * game.graphics.TILE_HEIGHT_PIXEL
      tile_height = 32
      if tileset is "monsters"
        tileset = game.graphics.tilesets.monsters
        tile_height = 32
      else if tileset is "characters"
        tileset = game.graphics.tilesets.characters
        y_pixel -= 16
        tile_height = 48
      game.graphics.handle.drawImage tileset, tile_x * game.graphics.TILE_WIDTH_PIXEL, tile_y * tile_height, game.graphics.TILE_WIDTH_PIXEL, tile_height, x_pixel, y_pixel, game.graphics.TILE_WIDTH_PIXEL, tile_height

    drawTile: (x, y, tile) ->
      x_pixel = x * game.graphics.TILE_WIDTH_PIXEL
      y_pixel = y * game.graphics.TILE_HEIGHT_PIXEL
      
      #console.log(x,y);
      return  if not tile? or isNaN(tile[0])
      game.graphics.handle.drawImage game.graphics.tilesets.terrain, 0, tile[0] * game.graphics.TILE_HEIGHT_PIXEL, game.graphics.TILE_WIDTH_PIXEL, game.graphics.TILE_HEIGHT_PIXEL, x_pixel, y_pixel, game.graphics.TILE_WIDTH_PIXEL, game.graphics.TILE_HEIGHT_PIXEL

  map:
    WIDTH_TILE: 200
    HEIGHT_TILE: 200 #was 200 each
    colors:
      black: "rgb(0,0,0)"

    data: []
    getTile: (x, y) ->
      tile = game.map.data[x][y]
      data = {}
      
      #if (tile && typeof tile[0] != 'undefined') {
      #data.tile = app.graphics.tilesets.descriptors.terrain[tile[0]];
      # }
      #if (tile && typeof tile[1] != 'undefined') {
      #data.health = tile[1];
      # }
      data

    render: ->
      
      # immediately draw canvas as black
      game.graphics.handle.fillStyle = game.map.colors.black
      game.graphics.handle.fillRect 0, 0, game.graphics.viewport.WIDTH_PIXEL, game.graphics.viewport.HEIGHT_PIXEL
      i = undefined
      j = undefined
      mapX = 0
      mapY = 0
      tile = undefined
      j = 0
      while j < game.graphics.viewport.HEIGHT_TILE
        i = 0
        while i < game.graphics.viewport.WIDTH_TILE
          mapX = i + game.graphics.viewport.x
          mapY = j + game.graphics.viewport.y
          tile = (if (game.map.data[mapX] and game.map.data[mapX][mapY]) then game.map.data[mapX][mapY] else null)
          
          #console.log(mapX,mapY);
          game.graphics.drawTile i, j, tile
          i++
        j++

  downloadTiles: ->
    $.get("/assets/tilesets/data.json").pipe (data) ->
      
      #app.chat.message('Client', 'Tileset Descriptors done.', 'client');
      game.graphics.tilesets.descriptors = data
      true


  downloadMap: ->
    $.get("/map").pipe (data) ->
      
      #app.chat.message('Client', 'Map data done.', 'client');
      game.map.data = data
      true


  start: ->
    $(".gamelayer").hide()
    $("#gameinterfacescreen").show()
    game.running = true
    game.refreshBackground = true
    game.drawingLoop()
    $("#gamemessages").html ""
    
    # Initialize All Game Triggers
    i = game.currentLevel.triggers.length - 1

    while i >= 0
      game.initTrigger game.currentLevel.triggers[i]
      i--

  
  # The map is broken into square tiles of this size (20 pixels x 20 pixels)
  gridSize: 20
  
  # Store whether or not the background moved and needs to be redrawn
  refreshBackground: true
  
  # A control loop that runs at a fixed period of time
  animationTimeout: 100 # 100 milliseconds or 10 times a second
  offsetX: 0 # X & Y panning offsets for the map
  offsetY: 0
  panningThreshold: 60 # Distance from edge of canvas at which panning starts
  panningSpeed: 10 # Pixels to pan every drawing loop
  handlePanning: ->
    
    # do not pan if mouse leaves the canvas
    return  unless mouse.insideCanvas
    if mouse.x <= game.panningThreshold
      if game.offsetX >= game.panningSpeed
        game.refreshBackground = true
        game.offsetX -= game.panningSpeed
    else if mouse.x >= game.canvasWidth - game.panningThreshold
      if game.offsetX + game.canvasWidth + game.panningSpeed <= game.currentMapImage.width
        game.refreshBackground = true
        game.offsetX += game.panningSpeed
    if mouse.y <= game.panningThreshold
      if game.offsetY >= game.panningSpeed
        game.refreshBackground = true
        game.offsetY -= game.panningSpeed
    else if mouse.y >= game.canvasHeight - game.panningThreshold
      if game.offsetY + game.canvasHeight + game.panningSpeed <= game.currentMapImage.height
        game.refreshBackground = true
        game.offsetY += game.panningSpeed
    
    # Update mouse game coordinates based on game offsets
    mouse.calculateGameCoordinates()  if game.refreshBackground

  animationLoop: ->
    
    # Animate the Sidebar
    sidebar.animate()
    
    # Process orders for any item that handles it
    i = game.items.length - 1

    while i >= 0
      game.items[i].processOrders()  if game.items[i].processOrders
      i--
    
    # Animate each of the elements within the game
    i = game.items.length - 1

    while i >= 0
      game.items[i].animate()
      i--
    
    # Sort game items into a sortedItems array based on their x,y coordinates
    game.sortedItems = $.extend([], game.items)
    game.sortedItems.sort (a, b) ->
      b.y - a.y + ((if (b.y is a.y) then (a.x - b.x) else 0))

    fog.animate()
    
    #Save the time that the last animation loop completed
    game.lastAnimationTime = (new Date()).getTime()

  drawingLoop: ->
    
    # Handle Panning the Map
    game.handlePanning()
    
    # Check the time since the game was animated and calculate a linear interpolation factor (-1 to 0)
    # since drawing will happen more often than animation
    game.lastDrawTime = (new Date()).getTime()
    if game.lastAnimationTime
      game.drawingInterpolationFactor = (game.lastDrawTime - game.lastAnimationTime) / game.animationTimeout - 1
      # No point interpolating beyond the next animation loop...
      game.drawingInterpolationFactor = 0  if game.drawingInterpolationFactor > 0
    else
      game.drawingInterpolationFactor = -1
    
    # Since drawing the background map is a fairly large operation,
    # we only redraw the background if it changes (due to panning)
    if game.refreshBackground
      
      #game.backgroundContext.drawImage(game.currentMapImage, game.offsetX, game.offsetY,game.canvasWidth, game.canvasHeight, 0, 0, game.canvasWidth, game.canvasHeight);
      #Dont just render map here, it has to redered with an offset, lets try that first. 
      #Not sure how we will handle panning on mobile devices.. so lets wait on panning for now.. There's more than enough tiles for a small dungeon anyways.
      game.map.render()
      game.refreshBackground = false
    
    # Clear the foreground canvas
    game.foregroundContext.clearRect 0, 0, game.canvasWidth, game.canvasHeight
    
    # Start drawing the foreground elements
    i = game.sortedItems.length - 1

    while i >= 0
      game.sortedItems[i].draw()  unless game.sortedItems[i].type is "bullets"
      i--
    
    # Draw the bullets on top of all the other elements
    i = game.bullets.length - 1

    while i >= 0
      game.bullets[i].draw()
      i--
    
    #fog.draw();
    
    # Draw the mouse
    mouse.draw()
    
    # Call the drawing loop for the next frame using request animation frame
    requestAnimationFrame game.drawingLoop  if game.running

  resetArrays: ->
    game.counter = 1
    game.items = []
    game.sortedItems = []
    game.buildings = []
    game.vehicles = []
    game.aircraft = []
    game.terrain = []
    game.triggeredEvents = []
    game.selectedItems = []
    game.sortedItems = []
    game.bullets = []

  add: (itemDetails) ->
    
    # Set a unique id for the item
    itemDetails.uid = game.counter++  unless itemDetails.uid
    item = window[itemDetails.type].add(itemDetails)
    
    # Add the item to the items array
    game.items.push item
    
    # Add the item to the type specific array
    game[item.type].push item
    game.currentMapPassableGrid = `undefined`  if item.type is "buildings" or item.type is "terrain"
    sounds.play item.name  if item.type is "bullets"
    item

  remove: (item) ->
    
    # Unselect item if it is selected
    item.selected = false
    i = game.selectedItems.length - 1

    while i >= 0
      if game.selectedItems[i].uid is item.uid
        game.selectedItems.splice i, 1
        break
      i--
    
    # Remove item from the items array
    i = game.items.length - 1

    while i >= 0
      if game.items[i].uid is item.uid
        game.items.splice i, 1
        break
      i--
    
    # Remove items from the type specific array
    i = game[item.type].length - 1

    while i >= 0
      if game[item.type][i].uid is item.uid
        game[item.type].splice i, 1
        break
      i--
    game.currentMapPassableGrid = `undefined`  if item.type is "buildings" or item.type is "terrain"

  
  # Selection Related Code 
  selectionBorderColor: "rgba(255,255,0,0.5)"
  selectionFillColor: "rgba(255,215,0,0.2)"
  healthBarBorderColor: "rgba(0,0,0,0.8)"
  healthBarHealthyFillColor: "rgba(0,255,0,0.5)"
  healthBarDamagedFillColor: "rgba(255,0,0,0.5)"
  lifeBarHeight: 5
  clearSelection: ->
    game.selectedItems.pop().selected = false  while game.selectedItems.length > 0

  selectItem: (item, shiftPressed) ->
    
    # Pressing shift and clicking on a selected item will deselect it
    if shiftPressed and item.selected
      
      # deselect item
      item.selected = false
      i = game.selectedItems.length - 1

      while i >= 0
        if game.selectedItems[i].uid is item.uid
          game.selectedItems.splice i, 1
          break
        i--
      return
    if item.selectable and not item.selected
      item.selected = true
      game.selectedItems.push item

  
  # Send command to either singleplayer or multiplayer object
  sendCommand: (uids, details) ->
    if game.type is "singleplayer"
      singleplayer.sendCommand uids, details
    else
      multiplayer.sendCommand uids, details

  getItemByUid: (uid) ->
    i = game.items.length - 1

    while i >= 0
      return game.items[i]  if game.items[i].uid is uid
      i--

  
  # Receive command from singleplayer or multiplayer object and send it to units
  processCommand: (uids, details) ->
    
    # In case the target "to" object is in terms of uid, fetch the target object
    toObject = undefined
    if details.toUid
      toObject = game.getItemByUid(details.toUid)
      
      # To object no longer exists. Invalid command
      return  if not toObject or toObject.lifeCode is "dead"
    for i of uids
      uid = uids[i]
      item = game.getItemByUid(uid)
      
      #if uid is a valid item, set the order for the item
      if item
        item.orders = $.extend([], details)
        item.orders.to = toObject  if toObject

  
  #Movement related properties
  speedAdjustmentFactor: 1 / 64
  turnSpeedAdjustmentFactor: 1 / 8
  rebuildPassableGrid: ->
    game.currentMapPassableGrid = $.extend(true, [], game.currentMapTerrainGrid)
    i = game.items.length - 1

    while i >= 0
      item = game.items[i]
      if item.type is "buildings" or item.type is "terrain"
        y = item.passableGrid.length - 1

        while y >= 0
          x = item.passableGrid[y].length - 1

          while x >= 0
            game.currentMapPassableGrid[item.y + y][item.x + x] = 1  if item.passableGrid[y][x]
            x--
          y--
      i--

  rebuildBuildableGrid: ->
    game.currentMapBuildableGrid = $.extend(true, [], game.currentMapTerrainGrid)
    i = game.items.length - 1

    while i >= 0
      item = game.items[i]
      if item.type is "buildings" or item.type is "terrain"
        y = item.buildableGrid.length - 1

        while y >= 0
          x = item.buildableGrid[y].length - 1

          while x >= 0
            game.currentMapBuildableGrid[item.y + y][item.x + x] = 1  if item.buildableGrid[y][x]
            x--
          y--
      else if item.type is "vehicles"
        
        # Mark all squares under or near the vehicle as unbuildable
        radius = item.radius / game.gridSize
        x1 = Math.max(Math.floor(item.x - radius), 0)
        x2 = Math.min(Math.floor(item.x + radius), game.currentLevel.mapGridWidth - 1)
        y1 = Math.max(Math.floor(item.y - radius), 0)
        y2 = Math.min(Math.floor(item.y + radius), game.currentLevel.mapGridHeight - 1)
        x = x1

        while x <= x2
          y = y1

          while y <= y2
            game.currentMapBuildableGrid[y][x] = 1
            y++
          x++
      i--

  
  # Functions for communicating with player
  characters:
    system:
      name: "System"
      image: "images/characters/system.png"

    op:
      name: "Operator"
      image: "images/characters/girl1.png"

    pilot:
      name: "Pilot"
      image: "images/characters/girl2.png"

    driver:
      name: "Driver"
      image: "images/characters/man1.png"

  showMessage: (from, message) ->
    sounds.play "message-received"
    character = game.characters[from]
    if character
      from = character.name
      if character.image
        $("#callerpicture").html "<img src=\"" + character.image + "\"/>"
        
        # hide the profile picture after six seconds
        setTimeout (->
          $("#callerpicture").html ""
        ), 6000
    
    # Append message to messages pane and scroll to the bottom
    existingMessage = $("#gamemessages").html()
    newMessage = existingMessage + "<span>" + from + ": </span>" + message + "<br>"
    $("#gamemessages").html newMessage
    $("#gamemessages").animate scrollTop: $("#gamemessages").prop("scrollHeight")

  
  # Message Box related code
  messageBoxOkCallback: `undefined`
  messageBoxCancelCallback: `undefined`
  showMessageBox: (message, onOK, onCancel) ->
    
    # Set message box text
    $("#messageboxtext").html message
    
    # Set message box ok and cancel handlers and enable buttons
    unless onOK
      game.messageBoxOkCallback = `undefined`
    else
      game.messageBoxOkCallback = onOK
    unless onCancel
      game.messageBoxCancelCallback = `undefined`
      $("#messageboxcancel").hide()
    else
      game.messageBoxCancelCallback = onCancel
      $("#messageboxcancel").show()
    
    # Display the message box and wait for user to click a button
    $("#messageboxscreen").show()

  messageBoxOK: ->
    $("#messageboxscreen").hide()
    game.messageBoxOkCallback()  if game.messageBoxOkCallback

  messageBoxCancel: ->
    $("#messageboxscreen").hide()
    game.messageBoxCancelCallback()  if game.messageBoxCancelCallback

  
  # Methods for handling triggered events within the game
  initTrigger: (trigger) ->
    if trigger.type is "timed"
      trigger.timeout = setTimeout(->
        game.runTrigger trigger
      , trigger.time)
    else if trigger.type is "conditional"
      trigger.interval = setInterval(->
        game.runTrigger trigger
      , 1000)

  runTrigger: (trigger) ->
    if trigger.type is "timed"
      
      # Re initialize the trigger based on repeat settings
      game.initTrigger trigger  if trigger.repeat
      
      # Call the trigger action
      trigger.action trigger
    else if trigger.type is "conditional"
      
      #Check if the condition has been satisfied
      if trigger.condition()
        
        # Clear the trigger
        game.clearTrigger trigger
        
        # Call the trigger action
        trigger.action trigger

  clearTrigger: (trigger) ->
    if trigger.type is "timed"
      clearTimeout trigger.timeout
    else clearInterval trigger.interval  if trigger.type is "conditional"

  end: ->
    
    # Clear Any Game Triggers
    if game.currentLevel.triggers
      i = game.currentLevel.triggers.length - 1

      while i >= 0
        game.clearTrigger game.currentLevel.triggers[i]
        i--
    game.running = false
