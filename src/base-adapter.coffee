{type,merge} = require "fairmont"

class BaseAdapter

  constructor: (@configuration) ->
    {@events} = @configuration
    
    if @configuration.log? and type(@configuration.log) == "function"
      @log = (msg) -> @configuration.log(msg)
    else if !@configuration.log? or @configuration.log == true
      @log = (msg) -> console.log msg
    else
      @log = -> # do nothing


class BaseCollection

  patch: (key,object) ->
    @events.source (events) =>
      _events = @get(key)
      _events.on "success", (data) =>
        if data?
          if type(data) == "array"
            if type(object) == "array"
              data = data.concat(object)
            else
              data.push(object)
          else if type(data) == "object"
            data = merge(data,object)
        __events = @put(key, data)
        __events.on "success", (data) -> events.emit "success", data
        __events.on "error", (err) -> events.emit "error", err
      _events.on "error", (err) -> events.emit "error", err


module.exports = {BaseAdapter,BaseCollection}