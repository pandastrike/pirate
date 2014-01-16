Suite = require "./interface"
{Mongo} = require "../src/index"
{EventChannel} = require "mutual"

events = new EventChannel

adapter = new Mongo.Adapter
  events: events
  port: 27017
  host: "127.0.0.1"
  database: "test"
  options:
    auto_reconnect: true

Suite.run "Mongo Adapter", adapter, ->
  adapter.close()