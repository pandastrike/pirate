w = require "when"
async = (require "when/generator").lift
{liftAll} = require "when/node"
{type,merge} = require "fairmont"
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

  connect: ->
    # create client
    @client = w.promise (resolve, reject) =>
      client = redis.createClient(@configuration.port, @configuration.host)
        .on "ready", =>
          @log "RedisAdapter: Connected to Redis server @ #{@configuration.host}:#{@configuration.port}"
          resolve liftAll(redis.RedisClient.prototype, liftCommands, client)
        .on "error", (err) =>
          @log "RedisAdapter: Error connecting to Redis server @ #{@configuration.host}:#{@configuration.port} - #{err}"
          reject err
              
  collection: (name) ->
    Collection.make
      name: name
      adapter: @
  
  close: async -> (yield @client).end()
    
class Collection extends BaseCollection

  @make: async (options) -> 
    options.client = yield options.adapter.client
    new @ options

  constructor: ({@name,@adapter, @client}) ->

  find: async (keys...) ->
    res = yield @client.hmget @name, keys
    res.map (item, index) -> 
      obj = null
      if item?
        obj = JSON.parse(item)
        # obj._id = keys[index]
      obj

  get: async (key) ->
    res = yield @client.hget @name, key
    if res? then JSON.parse(res) else null

  put: (key,object) ->
    @client.hset @name, key, JSON.stringify(object)

  delete: (key) ->
    @client.hdel @name, key

  all: async ->
    res = yield @client.hgetall @name
    data = []
    for key,value of res
      obj = JSON.parse(value)
      obj._id = key
      data.push(obj)
    data
    
  count: ->
    @client.hlen @name

module.exports = 
  Adapter: Adapter
  Collection: Collection
