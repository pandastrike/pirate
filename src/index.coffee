module.exports =
  Mongo: require "./mongo-adapter"
  Memory: require "./memory-adapter"
  ElasticSearch: require "./elasticsearch-adapter"
  Redis: require "./redis-adapter"
