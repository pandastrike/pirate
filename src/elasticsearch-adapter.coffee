{type,merge} = require "fairmont"
{overload} = require "typely"

ElasticSearchClient = require('elasticsearchclient')

defaults = 
  port: 9200
  host: "127.0.0.1"
  secure: true
  
class Adapter
  
  @make: (configuration) ->
    new @ configuration
  
  constructor: (configuration) ->
    configuration = merge( defaults, configuration )
    {@events} = configuration
    options = 
      host: configuration.host, 
      port: configuration.port, 
      secure: configuration.secure

    # Make sure we convert exceptions into error events
    @events.safely =>
      
      # Create the client object
      @client = new ElasticSearchClient(options)

      @events.emit "ready", @
              
  collection: (index, type) ->
    @events.source (events) =>
      result = Collection.make
        index: index
        type: type
        events: @events
        adapter: @
      events.emit "success", result
  
  close: ->
    
class Collection
  
  @make: (options) ->
    new @ options
  
  constructor: ({@index,@type,@events,@adapter}) ->
  
  find: overload (match, fail) ->    
    match "array", (keys) -> 
      @events.source (events) =>
        events.safely =>
          @adapter.client.count(
            @index, @type, {terms: {_id: keys}}
          )
          .on "data", (data) => 
            jsonData = JSON.parse(data)
            unless jsonData.error?
              findEvents = @find({terms: {_id: keys}}, {size: jsonData.count})
              findEvents.on "success", (data) ->
                events.emit "success", data
              findEvents.on "error", (err) ->
                events.emit "error", err
            else
              events.emit "error", jsonData.error
          .on "error", (err) -> 
            events.emit "error", err
          .exec()
    match "string", (queryString) -> 
      @find( {query_string: {query: queryString, default_operator: "AND"}}, {} )
    match "object", (query) -> @find( query, {} )
    match "string", "object", (queryString, options) -> 
      @find( {query_string: {query: queryString, default_operator: "AND"}}, options )
    match "object", "object", (query, options) -> 
      @events.source (events) =>
        events.safely =>
          @adapter.client.search(
              @index, @type, {query: query}, options
            )
            .on "data", (data) -> 
              jsonData = JSON.parse(data)
              unless jsonData.error?
                results = jsonData.hits.hits.map (dataElem) ->
                  result = dataElem._source
                  result._id = dataElem._id
                  result.score = dataElem._score
                  result
                events.emit "success", results
              else
                events.emit "error", jsonData.error
            .on "error", (err) -> 
              events.emit "error", err
            .exec()
    
  get: overload (match, fail) ->    
    match "string", (key) -> @get( _id: key )
    match "object", (query) ->
      @events.source (events) =>
        events.safely =>
          @adapter.client.search(
              @index, @type, {filter: {term: query}}
            )
            .on "data", (data) -> 
              jsonData = JSON.parse(data)
              unless jsonData.error?
                if jsonData.hits? and jsonData.hits.hits? and jsonData.hits.hits.length == 1
                  result = jsonData.hits.hits[0]._source
                  result._id = jsonData.hits.hits[0]._id
                  result.score = jsonData.hits.hits[0]._score
                else
                  result = null
                events.emit "success", result
              else
                events.emit "error", jsonData.error
            .on "error", (err) -> 
              events.emit "error", err
            .exec()

  put: overload (match,fail) ->
    match "string", "object", (key,object) -> @put( _id: key, object )
    match "object", "object", (key,object) -> 
      @events.source (events) =>
        @adapter.client.index(
            @index, @type, object, key._id
          )
          .on "data", (data) => 
            jsonData = JSON.parse(data)
            unless jsonData.error?
              events.emit "success", jsonData
            else
              events.emit "error", jsonData.error
          .on "error", (err) -> 
            events.emit "error", err
          .exec()
        

  delete: overload (match,fail) ->
    match "string", (key) -> @delete( _id: key )
    match "object", (key) ->
      @events.source (events) =>
        @adapter.client.deleteDocument(
            @index, @type, key._id
          )
          .on "data", (data) -> 
            jsonData = JSON.parse(data)
            unless jsonData.error?
              events.emit "success"
            else
              events.emit "error", jsonData.error
          .on "error", (err) -> 
            events.emit "error", err
          .exec()
          
  all: ->
    @events.source (events) =>
        events.safely =>
          countEvents = @count()
          countEvents.on "success", (resultCount) =>
            @adapter.client.search(
                @index, @type, query: {match_all: {}}, {size: resultCount}
              )
              .on "data", (data) -> 
                jsonData = JSON.parse(data)
                unless jsonData.error?
                  results = jsonData.hits.hits.map (dataElem) ->
                    result = dataElem._source
                    result._id = dataElem._id
                    result.score = dataElem._score
                    result
                  events.emit "success", results
                else
                  events.emit "error", jsonData.error
              .on "error", (err) -> 
                events.emit "error", err
              .exec()
          countEvents.on "error", (err) ->
            events.emit "error", err
    
  count: -> 
    @events.source (events) => 
      @adapter.client.count(
          @index, @type, {match_all: {}}
        )
        .on "data", (data) -> 
          jsonData = JSON.parse(data)
          unless jsonData.error?
            events.emit "success", jsonData.count
          else
            events.emit "error", jsonData.error
        .on "error", (err) -> 
          events.emit "error", err
        .exec()

module.exports = 
  Adapter: Adapter
  Collection: Collection