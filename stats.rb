require 'rubygems'
require 'sinatra'
require 'sqlite3'

#config constants
DATABASE_FILE = 'wb_sms_water.sqlite'

#HTML constants
PREFIX = '<html>'
BRAINS = '<style type="text/css">body{ background-color: #ddd; font-size: 3em; font-family: sans-serif; text-align: center; padding: 1em; } .special { background-color: #333; color: #fff; padding: .25em; } </style>' #.special:hover { text-decoration: underline; }
HEAD = "<head>\n\t<title>West Bengal SMS Water Reports: %s</title>\n #{BRAINS} </head>\n"
BODY = '<body>%s</body>'
SUFFIX = '</html>'

helpers do
  #short cut method to return first value from a (should be) select database query
  def q(query)
    #sanitized_query = SQLite3::Database.quote(query) ?
    @db.get_first_value(query)
  end
end

before do
  @db = SQLite3::Database.open(DATABASE_FILE)
end


get '/' do
  query = q('select count(*) from wb_water_sms')
  body = "There are <span class=\"special\">#{query}</span> reports to dig into!"
  PREFIX + (HEAD % 'Overview') + (BODY % body) + SUFFIX
end


