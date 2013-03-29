{EventChannel} = require "mutual"
Adapter        = require "../src"

events = new EventChannel

events.on "error", (error) -> console.log "Oh, dear!", error

events.on "books.delete", (key) ->
  console.log "Book '#{key}' has been deleted :("
events.on "books.new", ({key, object}) ->
  console.log "Got new book! :) key: '#{key}'", object

adapter = Adapter.make
  name: "file"
  path: "db"
  events: events

# db = Database.make
#   adapters: [
#     name: "memory"
#     events: events
#   ]

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
        collection.count()
      
      (count) ->
        console.log "Book count #{count}!"
        collection.all()

      (all) ->
        console.log all
        collection.delete "qubit"
        
      # Close the adapter
      ->
        console.log "Book removed!"
        adapter.close()

      
      ]
