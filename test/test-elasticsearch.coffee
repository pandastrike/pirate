{ElasticSearch} = require "../src/index"
{EventChannel} = require "mutual"
sleep = require "sleep"
util = require("util")

events = new EventChannel

events.on "error", (error) ->
  console.log "Oops!", error
  adapter.close()

adapter = new ElasticSearch.Adapter
  port: 9200
  host: "127.0.0.1"
  secure: false
  events: events

collection = null

events.on "ready", (adapter) ->

  console.log "Database is ready"
  
  do events.serially (go) ->

    # Delete index
    go ->
      console.log "Deleting index..."
      adapter.events.source (events) ->
        adapter.client.deleteIndex(
          "books"
          (err, data) ->
            console.log "Deleted index"
            events.callback err, data
        )

    # Create index
    go ->
      console.log "Creating index..."
      adapter.events.source (events) ->
        adapter.client.createIndex(
          "books"
          (err, data) -> 
            console.log "Created index"
            events.callback err, data
        )
    
    # Create mapping
    go ->
      console.log "Creating mapping..."
      adapter.events.source (events) ->
        adapter.client.putMapping(
          "books"
          "book"
          book:
            properties:
              key: type: "string"
              title: type: "string"
              author: type: "string"
              published: type: "string"
          (err, data) -> 
            console.log "Created mapping"
            events.callback err, data
        )

    # Get the collection
    go ->
      console.log "Getting collection..."
      adapter.collection "books", "book"

    # Save a book
    go (coll) ->
      console.log "Saving a book ..."
      collection = coll
      book = 
        title: "Test"
        author: "Tester"
        published: "2013"
      collection.put "test", book

    # Find the book
    go -> 
      console.log "Finding book ..."
      # sleep for 1 sec, ElasticSearch takes atmost 1 second to replicate
      sleep.sleep 1
      collection.find "test", {}

    go (findResults) ->
      console.log "Find results: ", util.inspect(findResults)

    # Find the book by key array
    go -> 
      console.log "Finding book by key array ..."
      collection.find ["test"]

    go (findResults) ->
      console.log "Find by key array results: ", util.inspect(findResults)

    # All books
    go -> 
      console.log "All books ..."
      collection.all()

    go (allBooks) ->
      console.log "All books: ", util.inspect(allBooks)

    # Count
    go -> 
      console.log "Counting ..."
      collection.count()

    go (count) ->
      console.log "Count: ", count

    # Get saved book
    go ->
      console.log "Getting saved book ..."
      collection.get "test"

    # Delete it
    go (book) ->
      console.log "Book: ", util.inspect(book)
      console.log "Deleting the book"
      collection.delete book

