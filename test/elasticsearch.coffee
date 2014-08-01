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
  port: 9200
  host: "127.0.0.1"
  secure: false
  events: events

events.once "ready", (adapter) ->

  console.log "Database is ready"
  
  do events.serially (go) ->

    # Delete index
    go ->
      console.log "Deleting index..."
      events.source (_events) ->
        adapter.client.deleteIndex(
          "books"
          (err, data) ->
            console.log "Deleted index"
            _events.callback err, data
        )

    # Create index
    go ->
      console.log "Creating index..."
      events.source (_events) ->
        adapter.client.createIndex(
          "books"
          (err, data) -> 
            console.log "Created index"
            _events.callback err, data
        )
    
    # Create mapping
    go ->
      console.log "Creating mapping"
      events.source (_events) ->
        adapter.client.putMapping(
          "books"
          "book"
          book:
            properties:
              foo: type: "integer"
              bar: type: "integer"
              baz: type: "integer"
          (err, data) -> 
            console.log "Created mapping"
            _events.callback err, data
        )

    go ->
      adapter = new ElasticSearch.Adapter
        port: 9200
        host: "127.0.0.1"
        secure: false
        events: events

      Suite.run "Elastic Adapter", adapter, ->
        events.source (_events) ->
          adapter.client.deleteIndex(
            "books"
            (err, data) ->
              console.log "Deleted index"
              adapter.close()
              _events.callback err, data
          )