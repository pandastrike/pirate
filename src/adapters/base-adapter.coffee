
# Abstract adapter class
class BaseAdapter
  
  constructor: (configuration) ->
    {@events} = configuration

  collection: (name) ->

  close: ->

  @make: (configuration) ->
    new @ configuration

module.exports = BaseAdapter

