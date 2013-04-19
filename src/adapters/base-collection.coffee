{EventChannel} = require "mutual"
{Catalog}  = require "fairmont"

Catalog.add "not-found", (key) ->
  "Item #{key} not found"

# Abstract collection class
class BaseCollection
  
  constructor: (options = {}) ->
    {@events} = options
    
    @events = new EventChannel unless @events?

  all: ->

  get: (key) ->
  
  put: (key, object) ->

  delete: (key) ->

  count: ->

  @make: (options) ->
    new @ options

  emit: (event, args...) =>
    @events.emit "#{@name}.#{event}", args...
    
  on: (args...) -> @events.on args...



module.exports = BaseCollection

