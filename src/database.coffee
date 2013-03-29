
class Database

  constructor: (options = {}) ->
    {@events, @adapters, @collections} = options
    @_adapters = {}

  load_adapters: ->
    for name, configuration of @adapters
      @_adapters[name] = Adapter.make configuration

