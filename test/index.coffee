{extname} = require "path"
{readdir} = require "fairmont"

allow = (file) -> extname(file) == ".coffee" and (file != "index.coffee")

# TODO: for this to work, we'd need to start the associated database
# first, before running the tests

for file in readdir(__dirname) when allow file
  require "./#{file}"
