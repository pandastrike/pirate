{type} = require "fairmont"

class BaseAdapter

  constructor: (@configuration) ->
    {@events} = @configuration
    
    if @configuration.log? and type(@configuration.log) == "function"
      @log = (msg) -> @configuration.log(msg)
    else if !@configuration.log? or @configuration.log == true
      @log = (msg) -> console.log msg
    else
      @log = -> # do nothing

module.exports = BaseAdapter