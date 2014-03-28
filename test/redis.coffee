Suite = require "./interface"
{Redis} = require "../src/index"
{EventChannel} = require "mutual"

events = new EventChannel

adapter = new Redis.Adapter
  events: events
  port: 6379
  host: "127.0.0.1"

Suite.run "Redis Adapter", adapter, ->
  adapter.close()