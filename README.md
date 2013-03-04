Pirate provides a simple key-value oriented storage interface with adapters for a variety of storage systems. This simplifies the interface to storage technologies and makes it easier to move between them. Obviously, many of the more sophisticated features of these systems are lost in the process, but the underlying storage implementation can always be accessed when necessary.

The elements of the interface are:

* `get key`

* `put object`

* `delete key`

Pirate uses a library called [Mutual][0] to provide a simple event-based interface. Each method returns an `events` object to which event handlers can be attached. Events "bubble up" (think DOM) so that error-handling no longer needs to be done local to the call.

For example, here's a simple program to `put` and `get` and object from MongoDB.

    {log} = console
    {Mongo} = require "pirate"
    {EventChannel} = require "mutual"
    
    # Create the top-level events object
    events = new EventChannel

    # Default error handler just logs the error
    events.on "error", (error) -> log error

    # Create an adapter, passing in the events object
    Mongo.Adapter.make
      events: events
      port: 27018
      host: "127.0.0.1"
      database: "foo"
      options:
        auto_reconnect: true

    # When the adapter is ready, we can do stuff
    events.on "ready", (adapter) ->

      # First, let's add a second event handler to 
      # close the connection and exit
      events.on "error", ->
        adapter.close
        process.exit -1
  
      # Okay, let's get the collection we're going to use
      (adapter.collection "bar")
  
      # Once we have the collection, let's put something
      .on "success", (collection) ->
        (collection.put baz: "hello")
    
        # If the put works, try getting the same thing back out
        .on "success", (object) ->
          (collection.get object.key)
          
          # If the get works, show the result and close the 
          # adapter because we're done!
          .on "success", (object) ->
            log object
            adapter.close()
            

