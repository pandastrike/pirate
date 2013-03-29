Collection = require "./collection"

class Database

  constructor: (options) ->
    {@events} = options

    @collections = {}

  collection: (name) ->
    if name of @collections then @collections[name]
    else
      @collections[name] = new Collection {name, @events}

  close: ->
    delete @collections


module.exports = Database
