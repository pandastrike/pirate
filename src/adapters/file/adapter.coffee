BaseAdapter = require "../base-adapter"
Database    = require "./database"
{resolve}   = require "path"

class FileAdapter extends BaseAdapter
  
  constructor: (configuration) ->
    super


    {path} = configuration
    @path = resolve process.cwd(), path

    @db = new Database {@events, @path}

    console.log "FileAdapter"
    @db.open (error) =>
      console.log "FileAdapter", error
      unless error
        @events.emit "ready", @
      else
        @events.emit "error", error

  collection: (name) ->
    @events.source (events) =>

      @db.collection name, (error, collection) =>
        unless error
          events.emit "success", collection
        else
          events.emit "error", error

  close: ->
    @db.close()

module.exports = FileAdapter
