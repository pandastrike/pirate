{type,merge} = require "fairmont"
{overload} = require "typely"
redis = require "redis"
{BaseAdapter,BaseCollection} = require ("./base-adapter")

defaults = 
  port: 6379
  host: "127.0.0.1"

class Adapter extends BaseAdapter
  
  @make: (configuration) ->
    new @ configuration
  
  constructor: (@configuration) ->
    @configuration = merge(defaults,@configuration)
    super(@configuration)

    # Make sure we convert exceptions into error events
    @events.safely =>
      @client = redis.createClient(@configuration.port, @configuration.host)
      @client.on "ready", =>
        @log "RedisAdapter: Connected to Redis server @ #{@configuration.host}:#{@configuration.port}"
        @events.emit "ready", @
      @client.on "error", (err) =>
        @log "RedisAdapter: Error connecting to Redis server @ #{@configuration.host}:#{@configuration.port} - #{err}"
        @events.emit "error", err
              
  collection: (name) ->
    @events.source (events) =>
      events.emit "success", 
        Collection.make
          name: name
          events: @events
          adapter: @
          log: @log
  
  close: -> @client.end()
    
class Collection extends BaseCollection
  
  @make: (options) ->
    new @ options

  constructor: ({@name,@events,@adapter,@log}) ->

  find: overload (match, fail) ->
    
    match "array", (keys) -> 
      @events.source (events) =>
        @adapter.client.hmget @name, keys, (err,res) =>
          unless err?
            data = res.map (item, index) -> 
              obj = null
              if item?
                obj = JSON.parse(item)
                obj._id = keys[index]
              obj
            events.emit "success", data
          else
            events.emit "error", err
    match "string", (key) -> @get(key)

  get: (key) ->
    @events.source (events) =>
      @adapter.client.hget @name, key, (err,res) =>
        unless err?
          data = if res? then JSON.parse(res) else null
          events.emit "success", data
        else
          events.emit "error", err

  put: (key,object) ->
    @events.source (events) =>
      @adapter.client.hset @name, key, JSON.stringify(object), (err,res) =>
        unless err?
          events.emit "success", object
        else
          events.emit "error", err

  delete: (key) ->
    @events.source (events) =>
      @adapter.client.hdel @name, key, (err,res) =>
        unless err?
          events.emit "success"
        else
          events.emit "error", err

  all: ->
    @events.source (events) =>
      @adapter.client.hgetall @name, (err,res) =>
        unless err?
          data = []
          for key,value of res
            obj = JSON.parse(value)
            obj._id = key
            data.push(obj)
          events.emit "success", data
        else
          events.emit "error", err
    
  count: ->
    @events.source (events) =>
      @adapter.client.hlen @name, (err,res) =>
        unless err?
          events.emit "success", res
        else
          events.emit "error", err

module.exports = 
  Adapter: Adapter
  Collection: Collection