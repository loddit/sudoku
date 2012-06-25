Grids = new Meteor.Collection("grids")
Players = new Meteor.Collection("players")
Messages = new Meteor.Collection("messages")
Games = new Meteor.Collection("games")
numbers = [ "", "1", "2", "3", "4", "5", "6", "7", "8", "9" ]

ImportPuzzle = ->
  _.each puzzles,(puzzle) ->
    Games.insert {puzzle: puzzle}

Meteor.methods(
  start_game: =>
    Grids.remove {}
    Players.remove {}
    Messages.remove {}
    if Games.find({}).count() == 0
      ImportPuzzle()
    games = Games.find({}).fetch()
    @current_game = games[Math.floor(Math.random() * games.length)]
    @current_game.start_at = new Date()
    Games.update @current_game._id, {$set:{restart_required_players: [],start_at: new Date()}}
    _.each @current_game.puzzle, (item, row) ->
      col = 0
      while col < item.length
        number = item[col]
        disabled = "disabled"
        if !number?
          number = ""
          disabled = ""
        Grids.insert
          number: number
          disabled: disabled
          row: row
          col: col
          block: (Math.floor(col / 3) + 3 * Math.floor(row / 3))
          player: "system"
          error: false
          color: "black"
        , ->
        col++
  ,
  get_current_game_hash: =>
    @current_game?._id
  get_current_time: =>
    new Date()
  get_start_at_time: =>
    if @current_game
      new Date(@current_game.start_at)
    
)

if Meteor.is_client
  (($) -> #jQuery cookie
    $.cookie = (key, value, options) ->
      if arguments.length > 1 and (not /Object/.test(Object::toString.call(value)) or value is null or value is undefined)
        options = $.extend({}, options)
        options.expires = -1  if value is null or value is undefined
        if typeof options.expires is "number"
          days = options.expires
          t = options.expires = new Date()
          t.setDate t.getDate() + days
        value = String(value)
        return (document.cookie = [ encodeURIComponent(key), "=", (if options.raw then value else encodeURIComponent(value)), (if options.expires then "; expires=" + options.expires.toUTCString() else ""), (if options.path then "; path=" + options.path else ""), (if options.domain then "; domain=" + options.domain else ""), (if options.secure then "; secure" else "") ].join(""))
      options = value or {}
      decode = (if options.raw then (s) -> s else decodeURIComponent)
      pairs = document.cookie.split("; ")
      i = 0
      pair = undefined
      while pair = pairs[i] and pairs[i].split("=")
        return decode(pair[1] or "")  if decode(pair[0]) is key
        i++
      null
  ) jQuery

  $ =>
    @current_player_hash = $.cookie('player_hash')
    @current_player_name = $.cookie('player_name')

  Meteor.startup =>
    Meteor.call 'get_current_game_hash',(error,result) =>
      @current_game_hash = result
      duration = 0
      setInterval( ()->
        time = (new Date(@server_time) - new Date(@start_at_time) + duration)/1000
        second = "#{Math.floor time%60}"
        second = "0#{second}" if second.length == 1
        min = Math.floor time/60
        duration += 1000
        $("#timer").html "#{min} : #{second}"
      ,1000)


  Template.timer.server_time = =>
    Meteor.call 'get_current_time',(error,result) =>
      @server_time = result
    @current_game_hash

  Template.timer.start_at_time = =>
    Meteor.call 'get_start_at_time',(error,result) =>
      @start_at_time = result
    @current_game_hash

  Template.join.events =
    "submit #join": (event) =>
      event.preventDefault()
      name = $.trim($("#name").val())
      if name == ''
        alert "Player name can not be empty!"
      else if  Players.find({}).count >= 9
        alert "Game limited to 9 player"
      else
        random_color = "##{Math.floor(Math.random() * 10)}#{Math.floor(Math.random() * 10)}#{Math.floor(Math.random() * 10)}"
        @current_player_hash = Players.insert(
          name: name
          color: random_color
          score: 0
        , =>
          @current_player = Players.findOne(@current_player_hash)
          @current_player_name = name
          $.cookie('player_hash',@current_player_hash)
          $.cookie('player_name', name)
        )
        $(event.target).html('')
        $(event.target).replaceWith Meteor.ui.render(Template.join)
        $("#say").replaceWith Meteor.ui.render(Template.say)

  Template.say.has_current_player = Template.join.has_current_player = ->
    if current_player_hash? and Players.findOne(current_player_hash)
      true
    else
      false

  Template.join.has_players = -> Players.find().count() > 0

  Template.join.player_name = -> if current_player_name? then current_player_name else ''
  
  Template.join.load_game_hash = =>
    Meteor.call 'get_current_game_hash',(error,result) =>
      @current_game_hash = result
  Template.sudoku.grids = -> Grids.find {}

  Template.grid.is_error = -> @error is true

  Template.player.is_current_player = ->
    if typeof (current_player_hash) is "undefined"
      false
    else
      @_id is current_player_hash

  Template.grid.events =
    change: (event) ->
      grid = $(event.target)
      number = $.trim(grid.val())
      cols = $(".grid[data-col=#{grid.attr("data-col")}]").not(grid)
      rows = $(".grid[data-row=#{grid.attr("data-row")}]").not(grid)
      blocks = $(".grid[data-block=#{grid.attr("data-block")}]").not(grid)
      set = _.uniq(_.map($.merge($.merge(cols, rows), blocks), (g) ->
        g.value
      ))
      if number isnt "" and _.include(set, number) or not _.include(numbers, number)
        error = true
      else
        error = false
      if number is ""
        player_hash = "system"
      else
        player_hash = current_player_hash
      Grids.update
        row: parseInt(grid.attr("data-row"))
        col: parseInt(grid.attr("data-col"))
      ,
        $set:
          number: number
          error: error
          color: current_player.color
          player: player_hash
      ,
        multi: true
      , ->
        remains = (Grids.find(error: "true").count() + Grids.find(number: "").count())
        if remains is 0
          winner = Players.findOne({},
            sort:
              score: -1
          )
          $("#dashboard").append Meteor.ui.render(Template.congratulation)

      score = Grids.find(
        player: current_player_hash
        error: false
      ).count()
      Players.update current_player_hash,
        $set:
          score: score

    click: (event) =>
      grid = $(event.target)
      @current_player ?= Players.findOne(@current_player_hash)
      if typeof (current_player) is "undefined"
        alert "Join game first :)"
        grid.blur()
        event.preventDefault()
        $("#name").focus()
      else
        grid_error = Grids.findOne(
          row: parseInt(grid.attr("data-row"))
          col: parseInt(grid.attr("data-col"))
        ).error
        grid_player = Grids.findOne(
          row: parseInt(grid.attr("data-row"))
          col: parseInt(grid.attr("data-col"))
        ).player
        if grid_player isnt current_player_hash and grid_player isnt "system" and !grid_error
          alert "This grid is holded by other player :("
          grid.blur()
          event.preventDefault()

  Template.rank.players = ->
    Players.find {}

  Template.restart.condition = -> Math.floor(Players.find({}).count()/2) + 1

  Template.restart.counter = ->
    current_game = Games.findOne current_game_hash
    current_game.restart_required_players.length or 0

  Template.restart.disabled = ->
    current_game = Games.findOne current_game_hash
    if current_player_hash in current_game.restart_required_players
      "disabled"
    else
      ''

  Template.restart.events =
    "submit #restart": (event) =>
      event.preventDefault()
      Games.update current_game_hash, {$push:{restart_required_players: @current_player_hash}}
      if Template.restart.counter() >= Template.restart.condition()
        Meteor.call('start_game')
        current_player_hash = current_player = undefined
        $(Template.join).replaceWith Meteor.ui.render(Template.join)

  Template.chatroom.messages = ->
    Messages.find {},
      sort:
        time: -1

  Template.say.events = submit: (event) =>
    event.preventDefault()
    say = $(event.target)
    @current_player ?= Players.findOne(@current_player_hash)
    if current_player and $.trim(say.find("input#content").val()) != ''
      Messages.insert
        content: say.find("input#content").val()
        player: current_player
        time: new Date()
      $(event.target).replaceWith Meteor.ui.render(Template.say)

if Meteor.is_server
  Meteor.startup ->
    Meteor.call('start_game')
