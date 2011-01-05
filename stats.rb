require 'rubygems'
require 'sinatra'
require 'sqlite3'
require 'time'

#config constants
DATABASE_FILE = 'wb_sms_water.sqlite'

#HTML constants
PREFIX = '<html>'
BRAINS = '<style type="text/css">body{ background-color: #ddd; font-size: 2em; font-family: sans-serif; text-align: center; padding: 1em; } .special { background-color: #333; color: #fff; padding: .25em; font-weight: bold; font-size: 1.25em; } .notes { font-size: .5em; }</style>' #.special:hover { text-decoration: underline; }
HEAD = "<head>\n\t<title>West Bengal SMS Water Reports: %s</title>\n #{BRAINS} </head>\n"
BODY = '<body>%s</body>'
SUFFIX = '</html>'

##########
# Helpers
##########
helpers do
  #short cut method to return first value from a (should be) select database query
  def q(query)
    #sanitized_query = SQLite3::Database.quote(query)
    #puts sanitized_query
    @db.get_first_value(query)
  end
  
  def counts()
    query = q('select count(*) from wb_water_sms')
    "<p>There are <span class=\"special\">#{query}</span> reports to dig into!</p>"
  end
  
  def histogram()
    first_ts = Time.parse(q('select date from wb_water_sms order by date asc limit 1')).to_i
    num_samples = q('select count(*) from wb_water_sms').to_i
    last_ts = Time.parse(q('select date from wb_water_sms order by date desc limit 1')).to_i

    #divide the total time that data has been collected into 10 buckets (alright 11 with the initial 0)
    bucket_width = (last_ts - first_ts)/10 #approximation...

    #find the number of revisions that have been added to the db during each of those buckets
    counts = [0] #start with 0 at the beginning, running sum of collected samples
    times = [first_ts]
    (1..10).each do |i|
      time = first_ts + bucket_width * i
      times << time
      date = Time.at(time).strftime('%Y-%m-%d')
      query = "select count(*) from wb_water_sms where date <= '#{date}'"
      #the running sum is the total that we had as of each time period
      counts << q(query).to_i
    end

    url = "http://chart.apis.google.com/chart?" + 
      "cht=lc" + #lxy" + 
      "&chs=600x400" +
      "&chd=t:" + counts.join(',') + #"&chd=t:0,10,20,40,80,90,95,99|0,20,30,40,50,60,70,80" + 
      "&chdl=Water reports" + 
      "&chxt=x,y" + 
      "&chtt=" + "Samples over time".gsub(/\ /, '+') +
      "&chxr=1,0," + num_samples.to_s +
      "&chds=0," + num_samples.to_s +
      "&chxl=0:|#{Time.at(times.first).strftime("%b %d %Y %H:%M")}|#{Time.at(times[5]).strftime("%b %d %Y")}|#{Time.at(times.last).strftime("%b %d %Y %H:%M")}" #"&chxl=0:|0|1|2|3|4|5|6|7|8|9|10"
    
    "<img src=\"#{url}\" alt=\"A sweet google chart, that you're not seeting, unfortunately.\" title=\"Histogram\" />"
  end
end

##########
# Filters
##########

before do
  @db = SQLite3::Database.open(DATABASE_FILE)
end

##########
# Routes
##########

get '/' do
  html_title = 'Overview'
  
  page_title = '<h1>Lumin Reports (West Bengal SMS Data)</h1>'
  p1 = counts()
  p2 = "<p class=\"notes\">For example, see this <a href=\"/histogram\">histogram</a>.</p>"
  body = page_title + p1 + p2
  
  PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
end

get '/histogram' do
  html_title = 'Data histogram'
  
  page_title = '<h1>Histogram of SMS Water Data (West Bengal)</h1>'
  
  image = histogram()
  
  p1 = '<p class="notes">This is a histogram of all of the data. Go <a href="/">home</a>.</p>'

  #counts.join(' ') + '; ' + times.join(' ')
  #Time.now.to_i.to_s + ' <br>' + 
  #Time.at(first_ts).to_s + ' <br>' + 
  #Time.at(last_ts).to_s + ' <br>' +
  body = page_title + 
    image + p1
  
  PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
end

get '/:district/histogram' do #=> district

end

#html_title = ''
#page_title = ''
#
#body = page_title + ...
#
#PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
#
