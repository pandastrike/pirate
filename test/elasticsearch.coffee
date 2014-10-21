{ElasticSearch} = require "../src/index"
{EventChannel} = require "mutual"
sleep = require "sleep"
util = require("util")
Suite = require "./interface"

events = new EventChannel

events.on "error", (error) ->
  console.log "Oops!", error
  adapter.close()

adapter = new ElasticSearch.Adapter
  host: "127.0.0.1:9200"
  events: events

events.once "ready", (adapter) ->

  console.log "Database is ready"
  
  do events.serially (go) ->

    # Delete index
    go ->
      events.source (_events) ->
        adapter.client.indices.exists(index: "books")
          .then (data) ->
            console.log "Index exists" if data
            _events.emit "success", data
          , (err) ->
            _events.emit "error", err
    go (exists) ->
      return if !exists 
      console.log "Deleting index..."
      events.source (_events) ->
        adapter.client.indices.delete(index: "books")
          .then (data) ->
            console.log "Deleted index"
            _events.emit "success"
          , (err) ->
            _events.emit "error", err

    # Create index
    go ->
      console.log "Creating index..."
      events.source (_events) ->
        adapter.client.indices.create(index: "books")
          .then (data) ->
            console.log "Created index"
            _events.emit "success"
          , (err) ->
            _events.emit "error", err
    
    # Create mapping
    go ->
      console.log "Creating mapping"
      events.source (_events) ->
        adapter.client.indices.putMapping(
          index: "books"
          type: "book"
          body:
            book:
              properties:
                foo: type: "integer"
                bar: type: "integer"
                baz: type: "integer"
        )
        .then (data) -> 
            console.log "Created mapping"
            _events.emit "success"
        , (err) ->
          _events.emit "error", err

    go ->
      adapter.close()
      
      adapter = new ElasticSearch.Adapter
        host: "127.0.0.1:9200"
        events: events

      Suite.run "Elasticsearc Adapter", adapter, ->
        adapter.client.indices.delete(index: "books")
          .then (data) ->
            console.log "Deleted index"
            adapter.close()
          , (err) ->
            console.log "Error deleting index:", err
            adapter.close()
