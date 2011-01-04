require 'rubygems'
require 'sinatra'

PREFIX = "<html>"
HEAD = "<head><title>West Bengal SMS Water Reports: %s</title></head>"
BODY = "<body>Helloworld!</body>"
SUFFIX = "</html>"

get '/' do
  PREFIX + HEAD + BODY + SUFFIX
end


