Collection = require "../../collection"
{toError} = require "fairmont"

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
      event = 
        if key of @collection then "update"
        else "new"
      @collection[key] = object
      @emit event, {key, object}
      events.emit "success"

  delete: (key) ->
    @events.source (events) =>
      if key of @collection
        delete @collection[key]
        @emit "delete", key
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

  emit: (event, args...) =>
    @events.emit "#{@name}.#{event}", args...


module.exports = MemoryCollection
