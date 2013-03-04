{log} = console
{Adapter} = (require "../src/mongo-adapter").Mongo
{EventChannel} = require "mutual"
events = new EventChannel

events.on "error", (error) -> log error

Adapter.make
  events: events
  port: 27018
  host: "127.0.0.1"
  database: "foo"
  options:
    auto_reconnect: true

events.on "ready", (adapter) ->

  events.on "error", ->
    adapter.close
    process.exit -1
  
  (adapter.collection "bar")
  
  .on "success", (collection) ->
    (collection.put baz: "hello")
    
    .on "success", (object) ->
      (collection.get object.key)

      .on "success", (object) ->
        log object
        adapter.close()
