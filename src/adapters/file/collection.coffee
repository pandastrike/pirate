Collection = require "../base-collection"
async      = require "async"
fs         = require "fs"
{toError}  = require "fairmont"

class FileCollection extends Collection

  encoding: 'utf8'

  constructor: (options) ->
    @_id = 1
    @id = "_id"
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
        callback (toError "not-found")(filename)

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
      object[@id] = key
      @writeFile filename, @encode(object), (error) =>
        unless error
          events.emit "success"
        else
          events.emit "error", error

  delete: (key) ->
    @events.source (events) =>
      filename = @filename(key)
      fs.unlink filename, (error) =>
        unless error
          events.emit "success"
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
    tasks = ( async.apply @readFile, file for file in files )
    async.parallelLimit tasks, 200, (error, results) =>
      unless error
        try
          callback null, (@decode res for res in results)
        catch _error
          callback _error
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
