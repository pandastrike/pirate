BaseAdapter = require "../base-adapter"
Collection  = require "./collection"
MongoDB     = require "mongodb"


class MongoAdapter extends BaseAdapter
  
  constructor: (configuration) ->
    super
    
    {host, port, auth, options, database} = configuration

    # Make sure we convert exceptions into error events
    @events.safely =>
      
      # Create the server object
      server = new MongoDB.Server(host, port, options)
      
      # Create the database
      @database = new MongoDB.Db database, server, w: 1
      
      # Open the database
      @database.open (error, database) =>
        _done = (error, database) =>
          unless error?
            @events.emit "ready", @
          else
            @events.emit "error", error

        if auth?
          {username, password} = auth
          database.authenticate username, password, (error, database) =>
            _done error, database
        else
          _done error, database
              
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
