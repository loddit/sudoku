Grid = new Meteor.Collection("grids")
Player = new Meteor.Collection("players")
Message = new Meteor.Collection("messages")
Game = new Meteor.Collection("ames")

Player.restart_condition = -> Math.floor(Player.find({online: true}).count()/2) + 1
Player.restart_counter = -> Player.find({required_restrat: true,online: true}).count()

numbers = [ "", "1", "2", "3", "4", "5", "6", "7", "8", "9" ]

format_time = (time) ->
  time = time/1000
  second = "#{Math.floor time%60}"
  second = "0#{second}" if second.length == 1
  min = Math.floor time/60
  "#{min}:#{second}"

Meteor.methods(
  import_puzzles: =>
    _.each puzzles,(puzzle) ->
      Game.insert {puzzle: puzzle}

  start_game: =>
    Grid.remove {}
    Player.remove {}
    Message.remove {}
    if Game.find({}).count() == 0
      Meteor.call("import_puzzles")
    games = Game.find({}).fetch()
    @current_game = games[Math.floor(Math.random() * games.length)]
    @online_players  = []
    _.each @current_game.puzzle, (item, row) =>
      col = 0
      while col < item.length
        number = item[col]
        disabled = "disabled"
        if !number?
          number = ""
          disabled = ""
        Grid.insert
          number: number
          disabled: disabled
          row: row
          col: col
          block: (Math.floor(col / 3) + 3 * Math.floor(row / 3))
          player: "system"
          error: false
          color: "black"
        , =>
        col++
    Game.update(@current_game._id, {$set: {finished: false}})
    Grid.find().observe(
        changed: =>
          if (Grid.find(error: true).count() + Grid.find(number: "").count()) == 0
            Game.update @current_game._id, {$set: {finished: true}}
      )
    @current_game.start_at = new Date()
  ,
  get_current_game_hash: =>
    @current_game?._id
  get_current_time: =>
    new Date()
  get_start_at_time: =>
    if @current_game
      new Date(@current_game.start_at)
  get_record: =>
    @current_game?.record
  set_record: =>
    if @current_game?.record?
      @game_duration = new Date() - new Date(@current_game.start_at)
      Game.update(@current_game?._id,{$set:{record: @game_duration}}) if @game_duration < @current_game?.record
    else if @current_game?
      @game_duration = new Date() - new Date(@current_game.start_at)
      Game.update(@current_game?._id,{$set:{record: @game_duration}})
  player_online_heartbeat: (player_hash) =>
      @online_players = @online_players.concat(player_hash) if @online_players? and player_hash not in @online_players
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
      @duration = 0
      Meteor.setInterval(
        () =>
          time = (new Date(@server_time) - new Date(@start_at_time) + duration)
          $("#timer").html format_time(time)
          $("#record").html "Record=#{format_time(@game_record)}" if @game_record
          if @current_player_hash and Player.findOne @current_player_hash
            if Meteor.status().connected
              Meteor.call('player_online_heartbeat',@current_player_hash, (error,result) -> {})
            else
              Player.update( @current_player_hash, {$set: {online: false}})
          duration += 1000
        ,
        1000)

  Template.status.server_time = =>
    Meteor.call 'get_current_time',(error,result) =>
      @server_time = result
    @current_game_hash

  Template.status.start_at_time = =>
    Meteor.call 'get_start_at_time',(error,result) =>
      @start_at_time = result
      @duration = 0
    @current_game_hash

  Template.status.record = =>
    Meteor.call 'get_record',(error,result) =>
      @game_record = result
    @current_game_hash

  Template.status.is_finish = ->
    if Game.findOne(@current_game_hash)?.finished
      $('#timer').attr('id','stoped_timer')
      true
    else
      $('#stoped_timer').attr('id','timer')
      false

  Template.join.events =
    "submit #join": (event) =>
      event.preventDefault()
      name = $.trim($("#name").val())
      if name == ''
        alert "Player name can not be empty!"
      else if  Player.find({online: true}).count() >= 9
        alert "Game limited to 9 player"
      else
        random_color = "##{Math.floor(Math.random() * 10)}#{Math.floor(Math.random() * 10)}#{Math.floor(Math.random() * 10)}"
        @current_player_hash = Player.insert(
          name: name
          color: random_color
          score: 0
          online: true
        , =>
          current_player = Player.findOne(@current_player_hash)
          @current_player_name = name
          $.cookie('player_hash',@current_player_hash)
          $.cookie('player_name', name)
        )
        $(event.target).html('')
        $(event.target).replaceWith Meteor.ui.render(Template.join)
        $("#say").replaceWith Meteor.ui.render(Template.say)

  Template.say.has_current_player = Template.join.has_current_player = ->
    if current_player_hash? and Player.findOne(current_player_hash)
      true
    else
      false

  Template.join.has_players = Template.status.has_players = -> Player.find().count() > 0

  Template.join.player_name = -> if current_player_name? then current_player_name else ''
  
  Template.join.load_game_hash = =>
    Meteor.call 'get_current_game_hash',(error,result) =>
      @current_game_hash = result
      @duration = 0

  Template.sudoku.grids = -> Grid.find {}

  Template.grid.is_error = -> @error is true

  Template.player.is_current_player = ->
    if not current_player_hash?
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
      Grid.update
        row: parseInt(grid.attr("data-row"))
        col: parseInt(grid.attr("data-col"))
      ,
        $set:
          number: number
          error: error
          color: Player.findOne(current_player_hash).color
          player: player_hash
      ,
        multi: true
      , ->

      score = Grid.find(
        player: current_player_hash
        error: false
      ).count()
      Player.update current_player_hash,
        $set:
          score: score

    click: (event) =>
      grid = $(event.target)
      if not Player.findOne(@current_player_hash)
        alert "Join game first :)"
        grid.blur()
        event.preventDefault()
        $("#name").focus()
      else
        grid_error = Grid.findOne(
          row: parseInt(grid.attr("data-row"))
          col: parseInt(grid.attr("data-col"))
        ).error
        grid_player = Grid.findOne(
          row: parseInt(grid.attr("data-row"))
          col: parseInt(grid.attr("data-col"))
        ).player
        if grid_player isnt current_player_hash and grid_player isnt "system" and !grid_error
          alert "This grid is holded by other player :("
          grid.blur()
          event.preventDefault()

  Template.rank.players = ->
    Player.find {}

  Template.restart.condition = -> Player.restart_condition()

  Template.restart.counter = -> Player.restart_counter()

  Template.restart.disabled = ->
    if current_player_hash and Player.findOne(current_player_hash).required_restrat
      "disabled"
    else
      ''

  Template.restart.events =
    "submit #restart": (event) =>
      event.preventDefault()
      Player.update @current_player_hash,{$set:{required_restrat: true}}, =>
        if Player.restart_counter() >= Player.restart_condition()
          Meteor.call('start_game')

  Template.chatroom.messages = ->
    Message.find {},{sort: {time: -1}}

  Template.say.events = submit: (event) =>
    event.preventDefault()
    say = $(event.target)
    if Player.findOne(@current_player_hash) and $.trim(say.find("input#content").val()) != ''
      Message.insert
        content: say.find("input#content").val()
        player: current_player
        time: new Date()
      $(event.target).replaceWith Meteor.ui.render(Template.say)

if Meteor.is_server
  Meteor.startup =>
    Meteor.call('start_game')
    Meteor.setInterval( ()=>
      Player.update({},{$set: {online: false}})
      Player.update(_id: {$in: @online_players},{$set: {online: true}})
      @online_players = []
    ,5000)
