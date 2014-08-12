{type,merge} = require "fairmont"
{overload} = require "typely"
ElasticSearchClient = require("elasticsearchclient")
{BaseAdapter,BaseCollection} = require ("./base-adapter")

defaults = 
  port: 9200
  host: "127.0.0.1"
  secure: true
  
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
      @client = new ElasticSearchClient(@configuration)

      # get Elasticsearch server version
      @client.createCall({path: "", method: "GET"}, @configuration)
        .on "data", (data) =>
          versionString = JSON.parse(data).version.number
          versionTokens = versionString.split(".")
          @esVersion = {major: parseInt(versionTokens[0]), minor: parseInt(versionTokens[1]), patch: parseInt(versionTokens[2])}
          @log "ElasticsearchAdapter: Connected to Elasticsearch server @ #{@configuration.host}:#{@configuration.port} v#{versionString}"
          @events.emit "ready", @
        .on "error", (err) =>
          @log "ElasticsearchAdapter: Error connecting to Elasticsearch server @ #{@configuration.host}:#{@configuration.port} - #{err}"
          @events.emit "error", err
        .exec()
              
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
    
class Collection extends BaseCollection

  @make: (options) ->
    new @ options

  constructor: ({@index,@type,@events,@adapter,@log}) ->
  
  find: overload (match, fail) ->    
    match "array", (keys) -> 
      @events.source (events) =>
        events.safely =>
          @adapter.client.count(
            @index, @type, {query: {terms: {_id: keys}}}
          )
          .on "data", (data) => 
            jsonData = JSON.parse(data)
            unless jsonData.error?
              findEvents = @find({filter: {terms: {_id: keys}}}, {size: jsonData.count})
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
      @find( {query: {query_string: {query: queryString, default_operator: "AND"}}}, {} )
    match "object", (query) -> @find( query, {} )
    match "string", "object", (queryString, options) -> 
      @find( {query: {query_string: {query: queryString, default_operator: "AND"}}}, options )
    match "object", "object", (query, options) -> 
      @events.source (events) =>
        events.safely =>
          @adapter.client.search(
              @index, @type, query, options
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
            @index, @type, object, key._id, options
          )
          .on "data", (data) => 
            jsonData = JSON.parse(data)
            unless jsonData.error?
              events.emit "success", object
            else
              events.emit "error", jsonData.error
          .on "error", (err) -> 
            events.emit "error", err
          .exec()
        
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
          @index, @type, {query: {match_all: {}}}
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