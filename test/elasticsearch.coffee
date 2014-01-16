{ElasticSearch} = require "../src/index"
{EventChannel} = require "mutual"
sleep = require "sleep"
util = require("util")

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
      adapter.events.source (events) ->
        adapter.client.deleteIndex(
          "books"
          (err, data) ->
            console.log "Deleted index"
            events.callback err, data
        )

    # Create index
    go ->
      console.log "Creating index..."
      adapter.events.source (events) ->
        adapter.client.createIndex(
          "books"
          (err, data) -> 
            console.log "Created index"
            events.callback err, data
        )
    
    # Create mapping
    go ->
      console.log "Creating mapping..."
      adapter.events.source (events) ->
        adapter.client.putMapping(
          "books"
          "book"
          book:
            properties:
              foo: type: "number"
              bar: type: "number"
              baz: type: "number"
          (err, data) -> 
            console.log "Created mapping"
            events.callback err, data
        )


      adapter = new ElasticSearch.Adapter
        port: 9200
        host: "127.0.0.1"
        secure: false
        events: events

      Suite = require "./interface"
      Suite.run("Elastic Adapter", adapter)