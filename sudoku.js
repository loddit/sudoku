Grids = new Meteor.Collection("grids");
Users = new Meteor.Collection("users");
var numbers = ['','1','2','3','4','5','6','7','8','9']

if (Meteor.is_client) {
  var random_color = "#" + Math.floor(Math.random()*10) + Math.floor(Math.random()*10) + Math.floor(Math.random()*10)
  current_user_hash = Users.insert({name:'test',color: random_color,score: 0});
  current_user = Users.findOne(current_user_hash);
  Template.map.grids = function(){
    return Grids.find({})
  }

  Template.grid.is_error = function(){
    return this.error === true;
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
      if (number == ''){ var user_hash = ''}else{ var user_hash = current_user_hash}
      Grids.update(
        {row: parseInt(grid.attr('data-row')),col: parseInt(grid.attr('data-col'))},
        {$set: { number: number, error: error, color: current_user.color, user: user_hash}},
        {multi: false},
        function(){
        }
      )
      var score = Grids.find({user:current_user_hash, error: false }).count()
      Users.update(current_user_hash, {$set: {score: score}})
    }
  }

  Template.rank.users = function(){
    return Users.find({})
  }
}

if (Meteor.is_server) {
  Meteor.startup(function () {
    Grids.remove({});
    Users.remove({});
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
        Grids.insert({number: number, disabled: disabled ,row: row, col: col,block: (Math.floor(col/3) + 3*Math.floor(row/3)),user: 'system',error: false});
      };
    });
  });
}
