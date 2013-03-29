Collection = require "./collection"
fs         = require "fs"

class Database

  constructor: (options) ->
    {@events, @path} = options

    @collections = {}

  open: (callback) ->
    @createDir @path, callback

  createDir: (path, callback) ->
    fs.exists path, (exists) =>
      unless exists
        fs.mkdir path, callback
      else callback()

  collection: (name, callback) ->
    path = "#{@path}/#{name}"
    @createDir path, (error) =>
      unless error
        callback null, Collection.make {name, path, @events} unless error
      else
        callback error

  close: ->
    delete @collections


module.exports = Database
