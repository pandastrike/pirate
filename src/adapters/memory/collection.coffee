Collection = require "../../collection"
{toError, Catalog} = require "fairmont"

Catalog.add "not-found", (key) ->
  "Item #{key} not found"

class MemoryCollection extends Collection

  constructor: (options) ->
    {@events, @name} = options
    @collection = {}

  get: (key) ->
    @events.source (events) =>
      events.safely =>
        if key of @collection
          events.emit "success", @collection[key]
        else
          events.emit "error", (toError "not-found")(key)

  put: (key, object) ->
    @events.source (events) =>
      @collection[key] = object
      events.emit "success"

  delete: (key) ->
    @events.source (events) =>
      if key of @collection
        delete @collection[key]
        events.emit "success"
      else
        events.emit "error", (toError "not-found")(key)

  all: ->
    @events.source (events) =>
      items = (value for name, value of @collection)
      events.emit "success", items

  count: ->
    @events.source (events) => 
      count = Object.keys(@collection).length
      events.emit "success", count


module.exports = MemoryCollection
