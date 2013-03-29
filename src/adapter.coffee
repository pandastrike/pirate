
# Abstract adapter class
class Adapter
  
  constructor: (@configuration) ->
    {@events} = @configuration

  collection: (name) ->

  close: ->

  @make: (configuration) ->
    new @ configuration

module.exports = Adapter

