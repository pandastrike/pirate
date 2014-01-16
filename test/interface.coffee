Testify = require "testify"
assert = require "assert"
{sleep} = require "sleep"

module.exports = class TestSuite

  @run: (title, adapter, onCompletion) -> 
    suite = new @(title, adapter)
    suite.run(onCompletion)

  constructor: (@title, @adapter) ->
    @key = "test-#{Date.now()}"
    @value = foo: 1, bar: 3, baz: 5

  run: (onCompletion) ->
    @adapter.events.on "error", => @adapter.close()
    Testify.test "Pirate Adapter Tests - #{@title}", (context) =>
      @initializeAdapter(context)
    Testify.emitter.on("done", onCompletion) if onCompletion?

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
    sleep 1
    context.test "Get a key-value pair", (context) =>
      events = @collection.get(@key)
      events.once "error", (error) => context.fail(error)
      events.once "success", (value) =>
        thisValue = foo: @value.foo, bar: @value.bar, baz: @value.baz
        thatValue = foo: value.foo, bar: value.bar, baz: value.baz
        assert.deepEqual thatValue, thisValue
        # memory adapter does not have a find method
        if @collection.find?
          @findValues(context)
        else
          @deleteKey(context)

  findValues: (context) ->
    context.test "Get a set of keys", (context) =>
      events = @collection.find [@key, "dummy"]
      events.once "error", (error) => context.fail(error)
      events.once "success", ([value]) =>
        thisValue = foo: @value.foo, bar: @value.bar, baz: @value.baz
        thatValue = foo: value.foo, bar: value.bar, baz: value.baz
        assert.deepEqual thatValue, thisValue
        @deleteKey(context)
        
  deleteKey: (context) ->
    context.test "Delete a key-value pair", (context) =>
      events = @collection.delete @key
      events.once "error", (error) => context.fail(error)
      events.once "success", =>
        context.pass()