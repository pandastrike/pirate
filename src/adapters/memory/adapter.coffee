Adapter    = require "../../adapter"
Database   = require "./database"

class MemoryAdapter extends Adapter
  
  constructor: ->
    super

    @db = new Database {@events}

    @events.emit "ready", @

  collection: (name) ->
    @events.source (events) =>

      collection = @db.collection(name)

      events.emit "success", collection

  close: ->
    @db.close()

module.exports = MemoryAdapter
