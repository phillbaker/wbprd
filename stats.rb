require 'rubygems'
require 'sinatra'
require 'sqlite3'

#config constants
DATABASE_FILE = 'wb_sms_water.sqlite'

#HTML constants
PREFIX = '<html>'
HEAD = "<head><title>West Bengal SMS Water Reports: %s</title></head>"
BODY = "<body>%s</body>"
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
  PREFIX + (HEAD % "Overview") + (BODY % "There are #{q('select count(*) from wb_water_sms')} reports to dig into!") + SUFFIX
end


