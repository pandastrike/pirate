{Catalog}  = require "fairmont"

Catalog.add "not-found", (key) ->
  "Item #{key} not found"

# Abstract collection class
class Collection
  
  constructor: (options) ->
    {@events} = options

  all: ->

  get: (key) ->
  
  put: (key, object) ->

  delete: (key) ->

  count: ->

  @make: (options) ->
    new @ options

  emit: (event, args...) =>
    @events.emit "#{@name}.#{event}", args...


module.exports = Collection

