{type,merge} = require "fairmont"

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
        
  get: (key) ->
    if type(key) == "array"
      @events.source (events) =>
        events.safely =>
          @collection.find { _id: { $in: key } }, (error,cursor) ->
            unless error?
              cursor.toArray (error,results) ->
                unless error?
                  events.emit "success", results
                else
                  events.emit "error", error
            else
              events.emit "error", error
    else
      @events.source (events) =>
        events.safely =>
          @collection.findOne {_id: "#{key}"}, (error,result) ->
            unless error?
              events.emit "success", result
            else
              events.emit "error", error

  put: (key,object) ->
    @events.source (events) =>
      # you can't update the _id field
      delete object._id
      object._id = key
      @collection.update {_id: key}, object, 
        {upsert: true, safe: true}, 
        (error,results) =>
          unless error?
            events.emit "success", object
          else
            events.emit "error", error

  # TODO: Should patch allow for upserts? Does that make sense?
  # I don't think so, but it's worth further consideration.
  patch: (key,patch) ->
    # you can't update the _id field
    delete patch._id
    @collection.update {_id: key}, {$set: patch},
      {safe: true},
      (error,results) =>
        unless error?
          events.emit "success", object
        else
          events.emit "error", error
        

  delete: (key) ->
    @events.source (events) =>
      @collection.remove {_id: key}, (error,results) =>
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