{type} = require "fairmont"
{overload} = require "typely"
{BaseAdapter,BaseCollection} = require ("./base-adapter")

class Adapter extends BaseAdapter

  @make: (configuration) ->
    new @ configuration

  constructor: (@configuration) ->
    super(@configuration)
    @database = {}
    @events.emit "ready", @

  collection: (name) ->
    @events.source (events) =>
      @database[name] = Collection.make
        collection: {}
        events: @events
        adapter: @
        log: @log
      events.emit "success", @database[name]

  close: ->

class Collection extends BaseCollection

  @make: (options) ->
    new @ options

  constructor: ({@events,@collection,@adapter,@log}) ->

  find: overload (match, fail) ->
    match "array", (keys) ->
      @events.source (events) =>
        values = keys.map (key) => @collection[key]
        events.emit "success", values
    match "string", (key) -> @get(key)

  get: (key) ->
    @events.source (events) =>
      events.emit "success", @collection[key]

  put: (key,object) ->
    @events.source (events) =>
      @collection[key] = object
      events.emit "success", object

  delete: (key) ->
    @events.source (events) =>
      object = @collection[key]
      delete @collection[key]
      events.emit "success"

  all: ->
    @events.source (events) =>
      values = (@collection[key] for key in Object.keys( @collection ))
      events.emit "success", values

  count: ->
    @events.source (events) =>
      events.emit "success",
        Object.keys( @collection ).length

module.exports =
  Adapter: Adapter
  Collection: Collection
