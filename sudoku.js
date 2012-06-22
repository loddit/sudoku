Grids = new Meteor.Collection("grids");
Players = new Meteor.Collection("players");
var numbers = ['','1','2','3','4','5','6','7','8','9']

  function GameInit(){
    Grids.remove({});
    Players.remove({});
    var game = [
            [2, ,5, , ,7, , ,6,],
            [4, , ,9,6, , ,2, ,],
            [ , , , ,8, , ,4,5,],
            [9,8, , ,7,4, , , ,],
            [5,7, ,8, ,2, ,6,9,],
            [ , , ,6,3, , ,5,7,],
            [7,5, , ,2, , , , ,],
            [ ,6, , ,5,1, , ,2,],
            [3, , ,4, , ,5, ,8,]
          ];

    _.each(game,function(item,row){
      for(var col = 0; col < item.length; col++){
        var number = item[col]
        var disabled="disabled"
        if(number == undefined ){
          number = ''
          disabled= ''
        }
        Grids.insert({number: number, disabled: disabled ,row: row, col: col,block: (Math.floor(col/3) + 3*Math.floor(row/3)),player: 'system',error: false});
      };
    });
  }
 
if (Meteor.is_client) {
  
  Template.form.events = {
    'submit': function(event){
      event.preventDefault();
      var random_color = "#" + Math.floor(Math.random()*10) + Math.floor(Math.random()*10) + Math.floor(Math.random()*10)
      current_player_hash = Players.insert({name: $('#name').val(),color: random_color,score: 0});
      current_player = Players.findOne(current_player_hash);
      $(event.target).replaceWith(Meteor.ui.render(Template.form))
    }
  }

  Template.form.has_current_player = function(){
    return typeof(current_player_hash) == 'undefined'
  }

  Template.sudoku.grids = function(){
    return Grids.find({})
  }

  Template.grid.is_error = function(){
    return this.error === true;
  }

  Template.player.is_current = function(){
    if (typeof(current_player_hash) == 'undefined'){
       return false
    }else{
        return this._id == current_player_hash;
    }
  }

  Template.grid.events = {
    'change': function(event){
      var grid = $(event.target);
      var number = $.trim(grid.val()) 
      var cols = $(".grid[data-col=" + grid.attr('data-col') + "]").not(grid)
      var rows = $(".grid[data-row=" + grid.attr('data-row') + "]").not(grid)
      var blocks = $(".grid[data-block=" + grid.attr('data-block') + "]").not(grid)
      var set = _.uniq(_.map($.merge($.merge(cols,rows),blocks),function(g){return g.value}))
      if (number != '' && _.include(set, number) || !_.include(numbers,number)){
        var error = true
      }else{
        var error = false
      }
      if (number == ''){ var player_hash = 'system'}else{ var player_hash = current_player_hash}
      Grids.update(
        {row: parseInt(grid.attr('data-row')),col: parseInt(grid.attr('data-col'))},
        {$set: { number: number, error: error, color: current_player.color, player: player_hash}},
        {multi: false},
        function(){
        }
      )
      var score = Grids.find({player:current_player_hash, error: false }).count()
      Players.update(current_player_hash, {$set: {score: score}})
    },
    'click': function(event){
      var grid = $(event.target);
      if ( typeof(current_player) == 'undefined'){
        alert("Join game first :)");
        grid.blur();
        event.preventDefault();
      }else{
        var grid_player = Grids.findOne({row: parseInt(grid.attr('data-row')),col: parseInt(grid.attr('data-col'))}).player 
        if(grid_player != current_player_hash && grid_player != 'system'){
          alert("This grid is holded by other player :(");
          grid.blur();
          event.preventDefault();
        }
      }
    }
  }

  Template.rank.players = function(){
    return Players.find({})
  }
}

if (Meteor.is_server) {
 Meteor.startup(function () {
    GameInit()
  });
}
