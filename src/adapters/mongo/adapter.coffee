Collection = require "./collection"
Adapter    = require "../../adapter"
MongoDB    = require "mongodb"


class MongoAdapter extends Adapter
  
  constructor: (@configuration) ->
    super
    
    {host, port, options, database} = @configuration

    # Make sure we convert exceptions into error events
    @events.safely =>
      
      # Create the server object
      server = new MongoDB.Server(host, port, options)
      
      # Create the database
      @database = new MongoDB.Db database, server, w: 1
      
      # Open the database
      @database.open (error, database) =>
        unless error?
          @events.emit "ready", @
        else
          @events.emit "error", error
              
  collection: (name) ->
    @events.source (events) =>
      @database.collection name, (error, collection) =>
        unless error?
          events.emit "success", 
            Collection.make 
              collection: collection
              events: @events
        else
          events.emit "error", error

  close: ->
    @database.close()

module.exports = MongoAdapter
