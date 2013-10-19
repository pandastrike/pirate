Testify = require "testify"
assert = require "assert"

module.exports = class TestSuite

  @run: (title, adapter) -> 
    suite = new @(title, adapter)
    suite.run()

  constructor: (@title, @adapter) ->
    @key = "test-#{Date.now()}"
    @value = foo: 1, bar: 3, baz: 5

  run: ->
    @adapter.events.on "error", => @adapter.close()
    Testify.test "Pirate Adapter Tests - #{@title}", (context) =>
      @initializeAdapter(context)

  initializeAdapter: (context) ->
    # We're assuming the client initialized the adapter --
    # we're just catching the ready event
    context.test "Initialize adapter", (context) =>
      @adapter.events.once "error", (error) => context.fail(error)
      @adapter.events.once "ready", => 
        @accessCollection(context)

  accessCollection: (context) ->
    context.test "Access a collection", (context) =>
      events = @adapter.collection("books")
      events.once "error", (error) => context.fail(error)
      events.once "success", (@collection) => @putKeyValue(context)

  putKeyValue: (context) ->
    context.test "Put a key-value pair", (context) =>
      events = @collection.put(@key, @value)
      events.once "error", (error) => context.fail(error)
      events.once "success", => @getKeyValue(context)

  getKeyValue: (context) ->
    context.test "Get a key-value pair", (context) =>
      events = @collection.get(@key)
      events.once "error", (error) => context.fail(error)
      events.once "success", (value) => 
        assert.deepEqual(value, @value)
        @findValues(context)

  findValues: (context) ->
    context.test "Get a set of keys", (context) =>
      events = @collection.find [@key, "dummy"]
      events.once "error", (error) => context.fail(error)
      events.once "success", ([value]) =>
        assert.deepEqual value, @value
        @deleteKey(context)
        
  deleteKey: (context) ->
    context.test "Delete a key-value pair", (context) =>
      events = @collection.delete @key
      events.once "error", (error) => context.fail(error)
      events.once "success", =>
        context.pass()
        @adapter.close()




            




# compose = (fns) ->
#   _fn = (args...) ->
#     fn = fns.shift()
#     fn?(args...)?.on? "success", _fn
#   _fn
    
# events.on "ready", (adapter) ->

#   console.log "Database is ready"
  
#   (adapter.collection "books").on "success", (collection) ->
    
    
#     do compose [
    
#       # Save the book
#       ->
      
#         console.log "Saving book ..."

#         book = 
#           title: "Qubit"
#           author: "Dan Yoder"
#           published: "2013"
      
#         collection.put "qubit", book
      
#       # Get it back
#       -> 

#         console.log "Book saved!"
#         collection.get "qubit"
        
#       # Patch it
#       (book) ->
#         collection.patch "qubit", author: "Finn Mack"
        
#       # Get it back again
#       -> 

#         console.log "Book updated!"
#         collection.get "qubit"

#       # Use a multi-key query
#       (book) ->
        
#         collection.find ["qubit","the martian chronicles"]
        
#       # Delete it
#       ([book]) ->
        
#         console.log "Title: #{book.title}, Author: #{book.author}"
#         collection.delete "qubit"
      
#       # Close the adapter
#       ->

#         console.log "Book removed!"
#         adapter.close()
      
#       ]

