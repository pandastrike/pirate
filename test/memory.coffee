Suite = require "./interface"
{Memory} = require "../src/index"
{EventChannel} = require "mutual"

events = new EventChannel

adapter = new Memory.Adapter
  events: events

Suite.run "Memory Adapter", adapter, ->
  adapter.close()