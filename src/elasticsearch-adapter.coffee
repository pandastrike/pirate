{type,merge} = require "fairmont"
{overload} = require "typely"
elasticsearch = require("elasticsearch")
{BaseAdapter,BaseCollection} = require ("./base-adapter")

defaults = 
  host: "127.0.0.1:9200"
  maxSockets: 10
  
class Adapter extends BaseAdapter
  esVersion: major: 0, minor: 0, patch: 0

  @make: (configuration) ->
    new @ configuration
  
  constructor: (@configuration) ->
    @configuration = merge(defaults,@configuration)
    super(@configuration)

    # Make sure we convert exceptions into error events
    @events.safely =>
      # Create the client object
      @client = new elasticsearch.Client(@configuration)

      # get Elasticsearch server version
      @client.info()
        .then (data) =>
          versionString = data.version.number
          versionTokens = versionString.split(".")
          @esVersion = {major: parseInt(versionTokens[0]), minor: parseInt(versionTokens[1]), patch: parseInt(versionTokens[2])}
          @log "ElasticsearchAdapter: Connected to Elasticsearch server @ #{@configuration.host} v#{versionString}"
          @events.emit "ready", @
        , (err) =>
          @log "ElasticsearchAdapter: Error connecting to Elasticsearch server @ #{@configuration.host}:#{@configuration.port} - #{err}"
          @events.emit "error", err
              
  collection: (index, type) ->
    @events.source (events) =>
      result = Collection.make
        index: index
        type: type
        events: @events
        adapter: @
        log: @log
      events.emit "success", result
  
  close: ->
    @client.close()
    
class Collection extends BaseCollection

  @make: (options) ->
    new @ options

  constructor: ({@index,@type,@events,@adapter,@log}) ->
  
  find: overload (match, fail) ->    
    match "array", (keys) -> 
      @events.source (events) =>
        events.safely =>
          @adapter.client.count(
            index: @index, type: @type, body: {query: terms: _id: keys}
          )
          .then (data) => 
            findEvents = @find({filter: {terms: {_id: keys}}}, {size: data.count})
            findEvents.on "success", (data) ->
              events.emit "success", data
            findEvents.on "error", (err) ->
              events.emit "error", err
          , (err) -> 
            events.emit "error", err
    match "string", (queryString) -> 
      @find( {query: {query_string: {query: queryString, default_operator: "AND"}}}, {} )
    match "object", (query) -> @find( query, {} )
    match "string", "object", (queryString, options) -> 
      @find( {query: {query_string: {query: queryString, default_operator: "AND"}}}, options )
    match "object", "object", (query, options) -> 
      @events.source (events) =>
        events.safely =>
          @adapter.client.search(
            merge({index: @index, type: @type, body: query}, options)
          )
          .then (data) -> 
            results = data.hits.hits.map (dataElem) ->
              result = dataElem._source
              result._id = dataElem._id
              result.score = dataElem._score
              result
            events.emit "success", results
          , (err) -> 
            events.emit "error", err
    
  get: overload (match, fail) ->    
    match "string", (key) -> @get( _id: key )
    match "object", (query) ->
      @events.source (events) =>
        events.safely =>
          @adapter.client.search(
            index: @index, type: @type, body: {filter: {term: query}}
          )
          .then (data) -> 
            if data.hits? and data.hits.hits? and data.hits.hits.length == 1
              result = data.hits.hits[0]._source
              result._id = data.hits.hits[0]._id
              result.score = data.hits.hits[0]._score
            else
              result = null
            events.emit "success", result
          , (err) -> 
            events.emit "error", err

  put: overload (match,fail) ->
    match "object", (object) -> 
      @put( _id: null, object, {} )
    match "string", "object", (key,object) -> 
      @put( _id: key, object, {} )
    match "string", "object", "object", (key,object,options) -> 
      @put( _id: key, object, options )
    match "object", "object", (key,object) -> 
      @put( key, object, {} )
    match "object", "object", "object", (key,object,options) -> 
      @events.source (events) =>
        @adapter.client.index(
          merge({index: @index, type: @type, id: key._id, body: object}, options)
        )
        .then (data) => 
          events.emit "success", object
        , (err) -> 
          events.emit "error", err
        
  patch: overload (match,fail) ->
    match "string", "object", (key,object) ->
      @patch( _id: key, object, {} )
    match "string", "object", "object", (key,object,options) ->
      @patch( _id: key, object, options )
    match "object", "object", (key,object) ->
      @patch( key, object, {} )
    match "object", "object", "object", (key,object,options) ->
      # even though we could use ES API 'update'
      # we are using get and index
      # as we need to return the new document
      @events.source (events) =>
        _events = @get(key._id)
        _events.on "success", (data) =>
          delete data._id
          delete data.score
          data = merge(data, object) if data?
          __events = @put(key._id, data, options)
          __events.on "success", (data) -> events.emit "success", data
          __events.on "error", (err) -> events.emit "error", err
        _events.on "error", (err) -> events.emit "error", err

  delete: overload (match,fail) ->
    match "string", (key) -> @delete( _id: key )
    match "object", (key) ->
      @events.source (events) =>
        @adapter.client.delete(
          index: @index, type: @type, id: key._id
        )
        .then (data) -> 
          events.emit "success"
        , (err) -> 
          events.emit "error", err
          
  all: ->
    @events.source (events) =>
      events.safely =>
        countEvents = @count()
        countEvents.on "success", (resultCount) =>
          @adapter.client.search(
            index: @index, type: @type, body: {query: {match_all: {}}}, size: resultCount
          )
          .then (data) -> 
            results = data.hits.hits.map (dataElem) ->
              result = dataElem._source
              result._id = dataElem._id
              result.score = dataElem._score
              result
            events.emit "success", results
          , (err) -> 
            events.emit "error", err
        countEvents.on "error", (err) ->
          events.emit "error", err
    
  count: -> 
    @events.source (events) => 
      @adapter.client.count(
        index: @index, type: @type, body: {query: {match_all: {}}}
      )
      .then (data) -> 
        events.emit "success", data.count
      , (err) -> 
        events.emit "error", err

module.exports = 
  Adapter: Adapter
  Collection: Collection