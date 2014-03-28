{type,merge} = require "fairmont"
{overload} = require "typely"
MongoDB = require "mongodb"
BaseAdapter = require ("./base-adapter")

defaults = 
  port: 27017
  host: "127.0.0.1"
  options:
    auto_reconnect: true
  
class Adapter extends BaseAdapter
  
  @make: (configuration) ->
    new @ configuration
  
  constructor: (@configuration) ->
    @configuration = merge(defaults,@configuration)
    super(@configuration)

    {host, port, options, database} = @configuration

    # Make sure we convert exceptions into error events
    @events.safely =>
      
      # Create the server object
      server = new MongoDB.Server( host, port, options )
      
      # Create the database
      @database = new MongoDB.Db( database, server, w: 1 )
      
      # Open the database
      @database.open (error,database) =>
        unless error?
          @log "MongoAdapter: Connected to MongoDB server @ #{@host}:#{port}"
          @events.emit "ready", @
        else
          @log "MongoAdapter: Error connecting to MongoDB server @ #{host}:#{port} - #{error}"
          @events.emit "error", error
              
  collection: (name) ->
    @events.source (events) =>
      @database.collection name, (error,collection) =>
        unless error?
          events.emit "success", 
            Collection.make 
              collection: collection
              events: @events
              adapter: @
              log: @log
        else
          events.emit "error", error

  
  close: ->
    @database.close()
    
class Collection
  
  @make: (options) ->
    new @ options
  
  constructor: ({@events,@collection,@adapter,@log}) ->
  
  find: overload (match, fail) ->
    
    match "array", (keys) -> @find( _id: keys )
    match "object", (query) ->
      _query = query
      for key, values of query
        _query[key] = $in: values
      @events.source (events) =>
        events.safely =>
          @collection.find _query, (error,cursor) =>
            if error
              events.emit "error", error
            else
              cursor.toArray( events.callback )
    
  get: overload (match, fail) ->
    
    match "string", (key) -> @get( _id: key )
    match "object", (query) ->
      @events.source (events) =>
        events.safely =>
            @collection.findOne query, events.callback

  put: overload (match,fail) ->
    match "string", "object", (key,object) -> @put( _id: key, object )
    match "object", "object", (key,object) ->
      @events.source (events) =>
        # you can't update the _id field
        if key._id?
          object._id = key._id
        else
          delete object._id
        @collection.update key, object,
          upsert: true, safe: true
          events.callback
        

  # TODO: Should patch allow for upserts? Does that make sense?
  # I don't think so, but it's worth further consideration.
  patch: overload (match,fail) ->
    match "string", "object", (key,patch) -> @patch( _id: key, patch )
    match "object", "object", (key,patch) ->
      @events.source (events) =>
        # you can't update the _id field
        delete patch._id
        @collection.update key, { $set: patch },
          { safe: true }, events.callback

  delete: overload (match,fail) ->
    match "string", (key) -> @delete( _id: key )
    match "object", (key) ->
      @events.source (events) =>
        @collection.remove key, (error,results) =>
          unless error?
            events.emit "success"
          else
            events.emit "error", error
          
  all: ->
    @events.source (events) =>
      @collection.find {}, (error,results) =>
        unless error?
          results.toArray (error,results) =>
            unless error?
              events.emit "success", results
            else
              events.emit "error", error
        else
          events.emit "error", error
    
  count: ->
    @events.source (events) => 
      @collection.count (error,count) =>
        unless error?
          events.emit "success", count
        else
          events.emit "error", error

module.exports = 
  Adapter: Adapter
  Collection: Collection