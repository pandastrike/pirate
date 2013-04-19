Collection = require "../base-collection"

class MongoCollection extends Collection

  constructor: (options) ->
    super
    
    {@collection} = options

  get: (key) ->
    @events.source (events) =>
      events.safely =>
        @collection.findOne {_id: key}, (error, result) ->
          unless error?
            # delete the _id field so we don't get strange
            # results later ...
            delete result._id if result?
            events.emit "success", result
          else
            events.emit "error", error

  put: (key, object) ->
    @events.source (events) =>
      @collection.update {_id: key}, {$set: object}, 
        {upsert: true, safe: true}, 
        (error, results) =>
          unless error?
            events.emit "success", results
          else
            events.emit "error", error

  delete: (key) ->
    @events.source (events) =>
      @collection.remove {_id: key}, (error, results) =>
        unless error?
          events.emit "success"
        else
          events.emit "error", error

  all: ->
    @events.source (events) =>
      @collection.find {}, (error, results) =>
        unless error?
          results.toArray (error, results) =>
            unless error?
              events.emit "success", results
            else
              events.emit "error", error
        else
          events.emit "error", error

  count: ->
    @events.source (events) => 
      @collection.count (error, count) =>
        unless error?
          events.emit "success", count
        else
          events.emit "error", error


module.exports = MongoCollection
