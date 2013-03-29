Collection = require "../../collection"
async      = require "async"
fs         = require "fs"
{toError}  = require "fairmont"

class FileCollection extends Collection

  encoding: 'utf8'

  constructor: (options) ->
    super

    {@name, @path} = options
    @collection = {}

  decode: (body) ->
    JSON.parse body

  encode: (body) ->
    JSON.stringify body

  filename: (key) =>
    "#{@path}/#{key}.json"

  exists: (filename, callback) =>
    fs.exists filename, callback

  readFile: (filename, callback) =>
    @exists filename, (exists) =>
      if exists
        fs.readFile filename, {@encoding}, (error, body) =>
          unless error
            callback null, body
          else
            callback error
      else
        callback true

  writeFile: (filename, body, callback) ->
    fs.writeFile filename, body, {@encoding}, callback

  get: (key) ->
    @events.source (events) =>
      events.safely =>
        filename = @filename(key)
        @readFile filename, (error, body) =>
          unless error
            events.emit "success", @decode body
          else
            events.emit "error", (toError "not-found")(key)

  put: (key, object) ->
    @events.source (events) =>
      filename = @filename(key)
      @writeFile filename, @encode(object), (error) =>
        unless error
          events.emit "success"
          @emit "put", key, object
        else
          events.emit "error", error

  delete: (key) ->
    @events.source (events) =>
      filename = @filename(key)
      fs.unlink filename, (error) =>
        unless error
          events.emit "success"
          @emit "delete", key
        else
          events.emit "error", error

  all: ->
    @events.source (events) =>
      fs.readdir @path, (error, files) =>
        unless error
          files = ("#{@path}/#{file}" for file in files)
          @readAll files, (error, items) =>
            unless error
              events.emit "success", items
            else
              events.emit "error", error
        else
          events.emit "error", error

  readAll: (files, callback) =>
    async.map files, @readFile, (error, results) =>
      unless error
        callback null, (@decode res for res in results)
      else
        callback error

  count: ->
    @events.source (events) => 
      fs.readdir @path, (error, files) =>
        unless error
          events.emit "success", files.length
        else
          events.emit "error", error

module.exports = FileCollection
