#SUDOKU
[Demo](http://sudoku.meteor.com) [unstable]

**SUDOKU** is a multiplayer sudoku game, open source under GPL Lisence.

This game is currently in development. rule and interface is uncertain, fork me and pull request for your good idea.

System is desgined for only one gamespace, to deploy by yourself is strongly recommended.

Deploy step:
  1. curl install.meteor.com | sh (install [Meteor](http://www.meteor.com), your need install [MongoDB](http://mongodb.org) and [Node.js](http://nodejs.org/) first)
  2. git clone this repo to somewhere
  3. cd somewhere && meteor (run at your local)
  4. cd somewhere && meteor deploy subdomain.meteor.com (deploy your game online)

Powerd and hosted by [Meteor](http://www.meteor.com). [see more](https://github.com/meteor/meteor)

Todo list

1. Use Games model for puzzle storage[Doing]
2. Use coffeescript[Done]
3. Use Less[Done]
4. Design Rule (Bouns and Penalty)
5. Use Cookie to remember player status[Done]
6. Save Best record[Done]
7. Timer system[Done]
8. Finish notice[Done]
