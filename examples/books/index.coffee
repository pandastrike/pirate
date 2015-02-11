assert = require "assert"
{call} = require "when/generator"
{Redis} = require "../../src/index"

adapter = new Redis.Adapter
  port: 6379
  host: "127.0.0.1"

book =
  key: "war-and-peace"
  title: "War and Peace"
  author: "Leo Tolstoy"
  published: "1969"

call ->

  # connect to the data store
  yield adapter.connect()

  # get a collection
  books = yield adapter.collection "books"

  # store things in it
  yield books.put book.key, book

  # get them back out
  assert.deepEqual (yield books.get book.key), book

  # update them
  yield books.patch book.key, published: "1869"
  book.published = "1869"
  assert.deepEqual (yield books.get book.key), book

  # TODO: We need a way to close an adapter...
  process.exit()
