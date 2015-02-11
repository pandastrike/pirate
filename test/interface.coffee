assert = require "assert"

{async, call} = do ->
  {lift, call} = require "when/generator"
  {async: lift, call}


test = async (name, fn) ->
  try
    yield fn()
    console.log name, "-- pass"
  catch error
    console.log name, "-- fail", error


module.exports = async (adapter) ->
  try

    book =
      title: "War and Peace"
      author: "Leo Tolstoy"
      published: "1969"
    key = "war-and-peace"
    books = null

    yield test "Connect to an adapter", async ->
      yield adapter.connect()

    yield test "Load a collection", async ->
      books = yield adapter.collection "books"
      assert.equal books.put?, true

    yield test "New collection is empty", async ->
      assert.equal (yield books.all()).length, 0

    yield test "Put an object into a collection", async ->
      yield books.put key, book

    yield test "Get an object from a collection", async ->
      _book = yield books.get key
      assert.deepEqual book, _book

    yield test "Find an object in a collection", async ->
      [_book] = yield books.find key
      assert.deepEqual _book, book

    yield test "Patch an object in a collection", async ->
      yield books.patch key, published: "1869"

    yield test "Return all the objects in a collection", async ->
      _books = yield books.all()
      assert.equal _books.length, 1

    yield test "Delete an object in a collection", async ->
      yield books.delete key
      assert.equal (yield books.get key), null

    yield adapter.close()

  catch error
    console.log error
