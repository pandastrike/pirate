{type,merge} = require "fairmont"
{overload} = require "typely"

MongoDB = require "mongodb"

defaults = 
  port: 27017
  host: "127.0.0.1"
  options:
    auto_reconnect: true
  
class Adapter
  
  @make: (configuration) ->
    new @ configuration
  
  constructor: (configuration) ->
    configuration = merge( defaults, configuration )
    {@events} = configuration
    {host, port, options, database} = configuration

    # Make sure we convert exceptions into error events
    @events.safely =>
      
      # Create the server object
      server = new MongoDB.Server( host, port, options )
      
      # Create the database
      @database = new MongoDB.Db( database, server, w: 1 )
      
      # Open the database
      @database.open (error,database) =>
        unless error?
          @events.emit "ready", @
        else
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
        else
          events.emit "error", error

  
  close: ->
    @database.close()
    
class Collection
  
  @make: (options) ->
    new @ options
  
  constructor: ({@events,@collection,@adapter}) ->
        
  get: overload (match,fail) ->
    
    match "array", (keys) -> @get( _id: keys )
    match "string", (key) -> @get( _id: key )
    match "object", (query) ->

      singular = true
      _query = {}
      for key, value of query
        _query[ key ] = 
          if type( value ) == "array"
            { $in: value }
            singular = false
          else
            value

      @events.source (events) =>
        @events.safely =>
          if singular
            @collection.findOne _query, events.callback
          else
            @collection.find _query, (error,cursor) ->
              unless error?
                cursor.toArray events.callback
              else
                events.emit "error", error

  put: overload (match,fail) ->
    match "string", "object", (key,object) -> @put( _id: key, object )
    match "object", "object", (key,object) ->
      @events.source (events) =>
        # you can't update the _id field
        object._id = key._id
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