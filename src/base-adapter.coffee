{type,merge} = require "fairmont"
{call} = require "when/generator"

# The BaseAdapter is basically here for future use
class BaseAdapter
  constructor: ->

class BaseCollection

  patch: (key, object) ->
    call =>
      data = yield @get(key)
      switch type(data)
        when "array"
          if type(object) == "array"
            data.concat object
          else
            data.push object
        when "object"
          data = merge data, object
      yield @put key, data

module.exports = {BaseAdapter,BaseCollection}
