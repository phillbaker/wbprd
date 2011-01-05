##########
# File: stats.rb
# Description: simple service to serve data/graphs about the West Bengal Water SMS data set.
# We're using get paramters because they're non-linear, and we can specify any number of the location parameters we want, or not...
##########

require 'rubygems'
require 'sinatra'
require 'sqlite3'
require 'time'

##########
# Constants
##########

#config constants
DATABASE_FILE = 'wb_sms_water.sqlite'

#HTML constants
PREFIX = '<html>'
BRAINS = '<style type="text/css">body{ background-color: #ddd; font-size: 2em; font-family: sans-serif; text-align: center; padding: 1em; } .special { background-color: #333; color: #fff; padding: .33em .33em .25em .25em; font-weight: bold; font-size: 1.25em; } .notes { font-size: .5em; }</style>' #.special:hover { text-decoration: underline; }
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
    #puts query
    @db.get_first_value(query)
  end
  
  #sanizite and set to known state for query params
  def process_params(opts)
    #nil should default to all for most of these, use empty strings here so we can check for allowed values easily below
    defaults = {
      :district => nil, #the below are all geo locations
      :block => nil,
      :panchayat => nil,
      :mouza => nil,
      :hamlet => nil,
      :well => nil, #end of geo locations
      :type => nil, #public/private/both
      :report => nil, #what contaminant to report on, nil is simply a record in the db (ie all)
      :time => nil, #defaults to all records in existence
      :operation => :count #reports, histogram, cot (change over time), coverage; defaults to counts of records
      #TODO if we're really just serving data, we should probably put a max number of records...
      #also be ready for a format
    }
    
    allowed_options = { # TODO the good way to do this would be to see if we respond_to?(:operation) or it's in the table
      :district => [nil], 
      :block => [nil], 
      :panchayat => [nil], 
      :mouza => [nil], 
      :hamlet => [nil], 
      :well => [nil], 
      :type => [:public, :private, nil],  #TODO #:public, :private, 
      :report => [nil], 
      :time => [nil], 
      :operation => [:count, :histogram]
    }
    #need to convert string values of keys to symbols
    ret = defaults.merge(opts.inject({}){|hsh,(k,v)| hsh[k.to_sym] = v; hsh}) 
    #TODO the below is poorly executed, there's gotta be a better way to do this
    #TODO check all the geo data to make sure it exists/it's sanitary
    #check the type
    ret[:type] = check_allowed_param(defaults[:type], allowed_options[:type], ret[:type])  
    #check the report
    ret[:report] = check_allowed_param(defaults[:report], allowed_options[:report], ret[:report])
    #check the time
    ret[:time] = check_allowed_param(defaults[:time], allowed_options[:time], ret[:time])
    #check the operation,
    ret[:operation] = check_allowed_param(defaults[:operation], allowed_options[:operation], ret[:operation])
    ret
  end
  
  #allowed should be an array of symbols
  def check_allowed_param(default, allowed, curr)
    ret = default
    if curr
      sym = curr.to_s.downcase.to_sym
      #raise NotImplementedError, curr.to_s unless
      ret = sym if allowed.include?(sym) #this shouldn't fail silently...
    end
    ret
  end
  
  def counts(where = '') #location = {}, type = nil, report
    query = q('select count(*) from wb_water_sms' + (where.empty? ? where : " where #{where}"))
    "<p>There are <span class=\"special\">#{query}</span> reports to dig into!</p>"
  end
  
  def histogram_query(where = '')
    where = where.empty? ? where : " where #{where} "
    first_ts = Time.parse(q("select date from wb_water_sms #{where} order by date asc limit 1")).to_i
    num_samples = q("select count(*) from wb_water_sms #{where} ").to_i
    #TODO static date that limits us to the data we have, future dates are not possible
    date = " date <= '2011-01-01' "
    last_ts = Time.parse(q("select date from wb_water_sms #{where.empty? ? " where #{date}" : where + ' and ' + date} order by date desc limit 1")).to_i

    #divide the total time that data has been collected into 10 buckets (alright 11 with the initial 0)
    bucket_width = (last_ts - first_ts)/10 #approximation...

    #find the number of revisions that have been added to the db during each of those buckets
    counts = [0] #start with 0 at the beginning, running sum of collected samples
    times = [first_ts]
    (1..10).each do |i|
      time = first_ts + bucket_width * i
      times << time
      date = Time.at(time).strftime('%Y-%m-%d')
      date_str = " date <= '#{date}' "
      query = "select count(*) from wb_water_sms #{where.empty? ? " where #{date_str}" : where + ' and ' + date_str} "
      #the running sum is the total that we had as of each time period
      counts << q(query).to_i
    end
    [counts, times, num_samples]
  end
  
  def histogram(where)
    counts, times, num_samples = histogram_query(where)

    url = "http://chart.apis.google.com/chart?" + 
      "cht=lc" + #lxy" + 
      "&chs=600x400" +
      "&chd=t:" + counts.join(',') + #"&chd=t:0,10,20,40,80,90,95,99|0,20,30,40,50,60,70,80" + 
      "&chdl=Water reports" + 
      "&chxt=x,y" + 
      "&chtt=" + "Reports over time".gsub(/\ /, '+') +
      "&chxr=1,0," + num_samples.to_s +
      "&chds=0," + num_samples.to_s +
      "&chxl=0:|#{Time.at(times.first).strftime("%b %d %Y %H:%M")}|#{Time.at(times[5]).strftime("%b %d %Y")}|#{Time.at(times.last).strftime("%b %d %Y %H:%M")}" #"&chxl=0:|0|1|2|3|4|5|6|7|8|9|10"
    
    "<img src=\"#{url}\" alt=\"A sweet google chart, that you're not seeting, unfortunately.\" title=\"Histogram\" />"
  end

  def main_page()
    html_title = 'Overview'

    page_title = '<h1>Lumin Reports</h1><h2>(West Bengal SMS Data)</h2>'
    p1 = counts()
    p2 = "<p class=\"notes\">For example, see this <a href=\"/?operation=histogram\">histogram</a>.</p>"
    body = page_title + p1 + p2

    PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
  end

  def count_page(where)
    html_title = 'Counts'

    page_title = '<h1>Counts of SMS Water Data (West Bengal)</h2>'
    p1 = counts(where)
    p2 = "<p class=\"notes\">For example, see this <a href=\"/?operation=histogram\">histogram</a>.</p>"
    body = page_title + p1 + p2

    PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
  end
  
  def histogram_page(where)
    html_title = 'Data histogram'

    page_title = '<h1>Histogram of SMS Water Data (West Bengal)</h1>'

    image = histogram(where)

    p1 = '<p class="notes">This is a histogram of all of the data. Go <a href="/">home</a>.</p>'

    body = page_title + image + p1

    PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
  end
  
  def not_found_page()
    PREFIX + (HEAD % 'Not found') + (BODY % "We couldn't find what your'e looking for, shoot us an e-mail and we'll see what we can do.") + SUFFIX
  end
  
  def not_implemented_page(error)
    PREFIX + (HEAD % 'Not found') + (BODY % "We haven't figured out how to do #{error} yet, but shoot us an e-mail and we'll try to get it done!") + SUFFIX
  end
end

##########
# Filters
##########

before do
  @db = SQLite3::Database.open(DATABASE_FILE)
end

not_found do 
  not_found_page()
end 

error NotImplementedError do
  not_implemented_page(request.env['sinatra.error'].message)
end

##########
# Routes
##########

get '/' do
  query_vars = process_params(params)
  
  #get rid of all nil values
  query_vars.delete_if do |k,v|
    v == nil
  end
  
  ret = ''
  #decide whether we head to the main page or we have query parameters
  if(query_vars.length == 1 && query_vars[:operation] == :count) #main page
    ret = main_page()
  else #we have some type of operation
    #break it down by operation, then feed the operation the geo, contaminent, time 
    case query_vars[:operation]
    when :count
      where = ''
      where += " type = '#{query_vars[:type]}' " if query_vars[:type]
      ret = count_page(where)
    when :histogram
      where = ''
      where += " type = '#{query_vars[:type]}' " if query_vars[:type]
      ret = histogram_page(where)
    else
      ret = not_implemented_page()
    end
  end
  ret
end

#get '/:district/:block/:panchayat/:mouza/:hamlet/:well/:type/:report/:time/:operation' do ||
#  
#end

#html_title = ''
#page_title = ''
#
#body = page_title + ...
#
#PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
#
