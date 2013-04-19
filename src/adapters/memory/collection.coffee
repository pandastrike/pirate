Collection       = require "../base-collection"
{toError, merge} = require "fairmont"

class MemoryCollection extends Collection

  constructor: (options) ->
    super
    
    {@name} = options
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
      object = merge {_id: key}, object
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
