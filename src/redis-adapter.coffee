w = require "when"
async = (require "when/generator").lift
{liftAll} = require "when/node"
{type, merge} = require "fairmont"
redis = require "redis"
{BaseAdapter,BaseCollection} = require ("./base-adapter")

# used to promisify RedisClient
# see https://gist.github.com/briancavalier/9982742
liftCommands = (proto, f, n) ->
  if (require "redis/lib/commands").indexOf(n) >= 0
    proto[n] = f
  proto

# default connection parameters
defaults =
  port: 6379
  host: "127.0.0.1"

class Adapter extends BaseAdapter

  @make: (configuration) ->
    new @ configuration

  constructor: (@configuration) ->
    @configuration = merge(defaults,@configuration)
    super(@configuration)
    @log ?= console.log

    @options = {}
    @options[k] = v for k, v of @configuration when k != "port" && k != "host"

  connect: ->
    w.promise (resolve, reject) =>
      # create client
      client = redis.createClient(@configuration.port, @configuration.host, @options)
        .on "ready", =>
          @log "RedisAdapter: Connected to Redis server @ #{@configuration.host}:#{@configuration.port}"
          @client = liftAll(redis.RedisClient.prototype, liftCommands, client)
          resolve @client
        .on "error", (err) =>
          @log "RedisAdapter: Error connecting to Redis server @ #{@configuration.host}:#{@configuration.port} - #{err}"
          reject err

  collection: (name) ->
    Collection.make
      name: name
      adapter: @

  close: async -> (yield @client).end()

class Collection extends BaseCollection

  @make: (options) -> new @ options

  constructor: ({@name,@adapter}) ->

  find: async (keys...) ->
    res = yield @adapter.client.hmget @name, keys
    res.map (item, index) ->
      obj = null
      if item?
        obj = JSON.parse(item)
        # obj._id = keys[index]
      obj

  get: async (key) ->
    res = yield @adapter.client.hget @name, key
    if res?
      # If we're pulling a buffer, no need to parse.
      if @adapter.options.return_buffers
        return res
      else
        return JSON.parse(res)
    else
      return null


  put: (key,object) ->
    if @adapter.options.return_buffers
      # If we're storing a buffer, don't stringify.
      @adapter.client.hset @name, key, object
    else
      @adapter.client.hset @name, key, JSON.stringify(object)

  delete: (key) ->
    @adapter.client.hdel @name, key

  all: async ->
    res = yield @adapter.client.hgetall @name
    data = []
    for key,value of res
      obj = JSON.parse(value)
      obj._id = key
      data.push(obj)
    data

  count: ->
    @adapter.client.hlen @name

module.exports =
  Adapter: Adapter
  Collection: Collection
