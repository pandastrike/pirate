{type} = require "fairmont"

MongoDB = require "mongodb"

class Adapter
  
  @make: (configuration) ->
    new @ configuration
  
  constructor: (@configuration) ->
    {@events} = @configuration
    {host, port, options, database} = @configuration

    # Make sure we convert exceptions into error events
    @events.safely =>
      
      # Create the server object
      server = new MongoDB.Server(host, port, options)
      
      # Create the database
      @database = new MongoDB.Db database, server, w: 1
      
      # Open the database
      @database.open (error,database) =>
        unless error?
          @events.send "ready", @
        else
          @events.send "error", error
              
  collection: (name) ->
    @events.source (_events) =>
      @database.collection name, (error,collection) =>
        unless error?
          _events.send "success", 
            Collection.make 
              collection: collection
              events: @events
        else
          _events.send "error", error

  
  close: ->
    @database.close()
    
class Collection
  
  @make: (options) ->
    new @ options
  
  constructor: (options) ->
    {@events,@collection} = options
        
  get: (key) ->
    @events.source (_events) =>
      _events.safely =>
        id = new MongoDB.ObjectID(key)
        @collection.findOne {_id: id}, (error,result) ->
          unless error?
            result.key = result._id.toString()
            _events.send "success", result
          else
            _events.send "error", error

  put: (object) ->
    @events.source (_events) =>
      @collection.insert object, {safe: true}, (error,results) =>
        unless error?
          result = results[0]
          result.key = result._id.toString()
          _events.send "success", result
        else
          _events.send "error", error


module.exports = 
  Adapter: Adapter
  Collection: Collection