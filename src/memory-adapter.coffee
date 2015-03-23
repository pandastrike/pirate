w = require "when"
{clone} = require "fairmont"
{BaseAdapter,BaseCollection} = require ("./base-adapter")

class Adapter extends BaseAdapter

  @make: (configuration) ->
    new @ configuration

  constructor: (@configuration) ->
    super(@configuration)
    @database = {}

  connect: -> w @

  collection: (name) ->
    w @database[name] = Collection.make
      collection: {}
      adapter: @
      logger: @logger

  close: -> w @

class Collection extends BaseCollection

  @make: (options) -> new @ options

  constructor: ({@collection,@adapter}) ->

  find: (keys...) -> w.all ((@get key) for key in keys)

  get: (key) -> w clone @collection[key]

  put: (key,object) -> w @collection[key] = object

  delete: (key) ->
    old = @collection[key]
    delete @collection[key]
    w old

  all: -> @find.apply @, (Object.keys @collection)

  count: -> w (Object.keys @collection).length

module.exports =
  Adapter: Adapter
  Collection: Collection
