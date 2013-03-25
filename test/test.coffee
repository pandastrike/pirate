{Mongo} = require "../src/index"
{EventChannel} = require "mutual"

events = new EventChannel

events.on "error", (error) -> console.log "Oh, dear!", error

adapter = new Mongo.Adapter
  events: events
  port: 27017
  host: "127.0.0.1"
  database: "test"
  options:
    auto_reconnect: true

compose = (fns) ->
  _fn = (args...) ->
    fn = fns.shift()
    fn?(args...)?.on? "success", _fn
  _fn
    
events.on "ready", (adapter) ->

  console.log "Database is ready"
  
  (adapter.collection "books").on "success", (collection) ->
    
    
    do compose [
    
      # Save the book
      ->
      
        console.log "Saving book ..."

        book = 
          title: "Qubit"
          author: "Dan Yoder"
          published: "2013"
      
        collection.put "qubit", book
      
      # Get it back
      -> 

        console.log "Book saved!"
        collection.get "qubit"
    
      # Delete it
      (book) ->

        console.log "Title: #{book.title}, Author: #{book.author}"
        collection.delete "qubit"
      
      # Close the adapter
      ->

        console.log "Book removed!"
        adapter.close()
      
      ]
