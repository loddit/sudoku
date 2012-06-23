Grids = new Meteor.Collection("grids")
Players = new Meteor.Collection("players")
numbers = [ "", "1", "2", "3", "4", "5", "6", "7", "8", "9" ]

GameInit = ->
  Grids.remove {}
  Players.remove {}
  game = games[Math.floor(Math.random() * games.length)]
  _.each game, (item, row) ->
    col = 0
    while col < item.length
      number = item[col]
      disabled = "disabled"
      if number is`undefined`
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
      col++

if Meteor.is_client
  Template.form.events = submit: (event) ->
    event.preventDefault()
    random_color = "#{Math.floor(Math.random() * 10)}#{Math.floor(Math.random() * 10)}#{Math.floor(Math.random() * 10)}"
    current_player_hash = Players.insert(
      name: $("#name").val()
      color: random_color
      score: 0
    , ->
      current_player = Players.findOne(current_player_hash)
    )
    $(event.target).replaceWith Meteor.ui.render(Template.form)

  Template.form.has_current_player = ->
    typeof (current_player_hash) isnt "undefined" and Players.find()

  Template.sudoku.grids = ->
    Grids.find {}

  Template.grid.is_error = ->
    @error is true

  Template.player.is_current = ->
    if typeof (current_player_hash) is "undefined"
      false
    else
      @_id is current_player_hash

  Template.grid.events =
    change: (event) ->
      grid = $(event.target)
      number = $.trim(grid.val())
      cols = $(".grid[data-col=" + grid.attr("data-col") + "]").not(grid)
      rows = $(".grid[data-row=" + grid.attr("data-row") + "]").not(grid)
      blocks = $(".grid[data-block=" + grid.attr("data-block") + "]").not(grid)
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
        multi: false
      , ->
        remains = (Grids.find(error: "true").count() + Grids.find(number: "").count())
        if remains is 0
          winner = Players.findOne({},{sort: {score: -1}})
          $("#dashboard").append Meteor.ui.render(Template.congratulation)

      score = Grids.find(
        player: current_player_hash
        error: false
      ).count()
      Players.update current_player_hash,
        $set:
          score: score

    click: (event) ->
      grid = $(event.target)
      if typeof (current_player) is "undefined"
        alert "Join game first :)"
        grid.blur()
        event.preventDefault()
        $("#name").focus()
      else
        grid_player = Grids.findOne(
          row: parseInt(grid.attr("data-row"))
          col: parseInt(grid.attr("data-col"))
        ).player
        if grid_player isnt current_player_hash and grid_player isnt "system"
          alert "This grid is holded by other player :("
          grid.blur()
          event.preventDefault()

  Template.rank.players = ->
    Players.find {}

  Template.congratulation.events = "click #restart": (event) ->
    GameInit()
    current_player_hash = current_player = `undefined`
    $(Template.form).replaceWith Meteor.ui.render(Template.form)
    $(event.target).parent().remove()

if Meteor.is_server
  __meteor_bootstrap__.require "#{__meteor_bootstrap__.require('path').resolve()}/games.js"
  Meteor.startup ->
    GameInit()
