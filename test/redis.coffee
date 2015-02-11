tests = require "./interface"
{Redis} = require "../src/index"

tests new Redis.Adapter
  port: 6379
  host: "127.0.0.1"

