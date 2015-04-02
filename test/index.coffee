{extname} = require "path"
{readdir} = require "fairmont"

# TODO: we should probably NOT run the tests and
# just issue a warning if the associated database
# connection fails...

require "./memory.coffee"
require "./redis.coffee"
