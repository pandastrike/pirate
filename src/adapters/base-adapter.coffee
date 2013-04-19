{EventChannel} = require "mutual"

# Abstract adapter class
class BaseAdapter
  
  constructor: (configuration) ->
    {@events} = configuration

    @events = new EventChannel unless @events?

  collection: (name) ->

  close: ->

  @make: (configuration) ->
    new @ configuration

  on: (args...) -> @events.on args...
  emit: (args...) -> @events.emit args...

module.exports = BaseAdapter

