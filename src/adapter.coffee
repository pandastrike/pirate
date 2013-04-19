
# Universal adapter class
class Adapter
  
  constructor: ->

  @make: (configuration) ->
    {name} = configuration
    adapter = require("./adapters/#{name}")
    adapter.Adapter.make configuration

module.exports = Adapter
