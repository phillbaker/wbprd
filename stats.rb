##########
# File: stats.rb
# Description: simple service to serve data/graphs about the West Bengal Water SMS data set.
# We're using get paramters because they're non-linear, and we can specify any number of the location parameters we want, or not...
# Ignore extra get parameters and throw error on incorrect ones.
# What I really want is a URL-based DSL for information...
#
#TODO I'd like to automatically make a url-map or something that shows to which urls this code responds
#TODO use https://github.com/mattetti/googlecharts
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
BRAINS = '<style type="text/css">body{ background-color: #ddd; font-size: 2em; font-family: sans-serif; text-align: center; padding: 1em; } .special { background-color: #333; color: #fff; padding: .33em .33em .25em .25em; font-weight: bold; font-size: 1.25em; } .footnote { font-size: .5em; } .headnote { font-size: .5em; text-align: left; }</style>' #.special:hover { text-decoration: underline; }
HEAD = "<head>\n\t<title>West Bengal SMS Water Reports: %s</title>\n #{BRAINS} </head>\n"
BODY = '<body>%s</body>'
SUFFIX = '</html>'

##########
# Sinatra settings
##########

set :dump_errors, false

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
  
  #rows-query
  def r(query)#TODO , limit = 100, offset = 0)
    #alreays return the headers
    #query =~ /limit = [0-9]+$/ #make sure there's a limit
    @db.execute2(query)
    #return if there are more than 100 results...
  end
  
  #sanizite and set to known state for query params
  def process_params(opts)
    #nil should default to all for most of these, use empty strings here so we can check for allowed values easily below
    defaults = { #really, they're all nil, don't need any of this
      :type => nil, #public/private/both
      :report => nil, #what contaminant to report on, nil is simply a record in the db (ie all)
      :time => nil, #defaults to all records in existence
      :operation => nil #:count, reports, histogram, cot (change over time), coverage; defaults to counts of records
      #TODO if we're really just serving data, we should probably put a max number of records...
      #also be ready for a format
    }
    
    allowed_options = { # TODO the good way to do this would be to see if we respond_to?(:operation) or it's in the table
      :type => [:public, :private, nil],
      :report => [:arsenic,:tds,:salinity,:fluoride,:iron,:tc,:fc,:ph,:hardness,nil], #:all, :date?
      :time => [nil], 
      :operation => [:count, :avg, :max, :min, :histogram],
      :gt => [Float]
    }
    #convert string values of keys to symbols and then load it into defaults
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
    ret[:gt] = check_allowed_param(defaults[:gt], allowed_options[:gt], ret[:gt])
    ret
  end
  
  #allowed should be an array of symbols
  def check_allowed_param(default, allowed, curr)
    ret = default
    if curr
      if(allowed.is_a?(Class))
        #something like: ret = allowed.convert(curr.to_s) if allowed.convert?(curr.to_s)
      else
        sym = curr.to_s.downcase.to_sym
        ret = sym if allowed.include?(sym) #this shouldn't fail silently...
      end
      #TODOraise NotDoneYet, curr.to_s unless allowed.include?(sym)
    end
    ret
  end
  
  def count(select, where, group) #location = {}, type = nil, report
    q('select count(*) from wb_sms_water ' + (where.empty? ? where : " where #{where}") + (group.empty? ? group : " group by #{group} ")).to_i
  end
  
  #the html wrapped count()
  def counts(select, where, group) #location = {}, type = nil, report
    "<p>There are <span class=\"special\">#{count(select, where, group).to_s}</span> reports to dig into!</p>"
  end
  
  def histogram_query(where)
    where = where.empty? ? where : " where #{where} "
    first_ts = Time.parse(q("select date from wb_sms_water #{where} order by date asc limit 1")).to_i
    num_samples = q("select count(*) from wb_sms_water #{where} ").to_i
    #TODO static date that limits us to the data we have, future dates are not possible
    date = " date <= '2011-01-01' "
    last_ts = Time.parse(q("select date from wb_sms_water #{where.empty? ? " where #{date}" : where + ' and ' + date} order by date desc limit 1")).to_i

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
      query = "select count(*) from wb_sms_water #{where.empty? ? " where #{date_str}" : where + ' and ' + date_str} "
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
      "&chxs=0,676767,15|1,676767,14" +
      "&chxl=0:|#{Time.at(times.first).strftime("%b %d %Y")}|#{Time.at(times[5]).strftime("%b %d %Y")}|#{Time.at(times.last).strftime("%b %d %Y")}" #"&chxl=0:|0|1|2|3|4|5|6|7|8|9|10" # %H:%M
    
    "<img src=\"#{url}\" alt=\"A sweet google chart, that you're not seeting, unfortunately.\" title=\"Histogram\" />"
  end

  def data(select, where, group)
    select_sql = select.empty? ? ' * ' : select
    where_sql = where.empty? ? where : " where #{where} "
    group_sql = group.empty? ? group : " group by #{group} "
    #p "select #{select_sql} from wb_sms_water #{where_sql} #{group_sql} limit 100"
    [r("select #{select_sql} from wb_sms_water #{where_sql} #{group_sql} limit 100"), count('', where, group) >= 100] #return the query and whether there are more results
  end

  def main_page()
    html_title = 'Overview'

    page_title = '<h1>Lumin Reports</h1><h2>(West Bengal SMS Data)</h2>'
    p1 = counts('', '', '')
    p2 = "<p class=\"footnote\">For example, see this <a href=\"/?operation=histogram\">histogram</a>.</p>"
    body = page_title + p1 + p2

    PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
  end

  def table_page(select = '', where = '', group = '')
    res,more = data(select, where, group)
    
    html_title = 'data'
    
    page_title = '<h1>Data dump!</h1>' + (more ? '<h2>(there\'s more than this...)</h2>' : '')
    table = '<table><tr>%s</tr>%s</table>'
    headers = res[0]
    header_html = '<th>' + headers.join('</th><th>') + '</th>' #TODO put in explanations of what these are/units
    #header_html = headers.inject('<th>')
    data = res[1..-1]
    rows = data.collect do |row|
      '<td>' + row.join('</td><td>') + '</td>'
    end
    row_html = '<tr>' + rows.join('</tr><tr>') + '</tr>'
    body = page_title + table % [header_html, row_html]
    
    PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
  end
  
  #this makes some assumptions about the order of the items in select/where/group
  def table_links_page(hierarchy, current_level, select = '', where = '', group = '')
    res,more = data(select, where, group)

    html_title = 'data'
    #request.path
    page_title = '<h1>Well Finder</h1>' + (more ? '<h2>(there\'s more than this...)</h2>' : '')
    if(res.length > 1)
      table = '<table><tr>%s</tr>%s</table>'
      headers = res[0]
      header_html = '<th>' + headers.join('</th><th>') + '</th>' #TODO put in explanations of what these are/units
      #header_html = headers.inject('<th>')
      
      link = headers.collect{|o| hierarchy.include?(o.to_sym) && (current_level + hierarchy.index(o.to_sym)) < hierarchy.length * 2 - 1 } #everything but the last one
      path = request.path.split('/')
      rows = res[1..-1].collect do |row|
        #only want base urls for high-heirarchy levels
        #don't want links on the lowest level of the hierarhcy levels
        #TODO pass the query params of the url onto the next one
        ret = '<td>'
        (0..row.length).each do |i| 
          if(link[i]) 
            url = path[0..hierarchy.index(headers[i].to_sym)+1].collect{|o| !o.empty? && o.to_sym == :':all' ? row[i-1] : o }
            #grab the path for where we are in the row
            ret += "<a href=\"#{url.join('/') + "/#{row[i]}"}\">#{row[i]}</a>"
          else
            ret += row[i].to_s
          end
          ret += '</td><td>'
        end
        ret +=  "</td>\n"
        ret
      end
      row_html = '<tr>' + rows.join('</tr><tr>') + '</tr>'
      
      body = page_title + "<p class=\"headnote\"><a href=\"#{path[0..1].join('/')}\">Top summary level</a></p>\n" + table % [header_html, row_html]
    else
      body = '<p>Couldn\'t find anything with that designation.</p>' #TODO this or do 404?
    end
    
    PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
  end
  
  def count_page(select = '', where = '', group = '')
    html_title = 'Counts'

    page_title = '<h1>Counts of SMS Water Data (West Bengal)</h2>'
    p1 = counts(select, where, group)
    p2 = "<p class=\"footnote\">For example, see this <a href=\"/?operation=histogram\">histogram</a>.</p>"
    body = page_title + p1 + p2

    PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
  end
  
  def histogram_page(select = '', where = '')
    html_title = 'Data histogram'

    page_title = '<h1>Histogram of SMS Water Data (West Bengal)</h1>'

    image = histogram(where)

    p1 = '<p class="footnote">This is a histogram of all of the data. Go <a href="/">home</a>.</p>'

    body = page_title + image + p1

    PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
  end
  
  def not_found_page()
    PREFIX + (HEAD % 'Not found') + (BODY % "We couldn't find what you're looking for, shoot us an e-mail and we'll see what we can do.") + SUFFIX
  end
  
  def not_implemented_page(error = 'that')
    PREFIX + (HEAD % 'Not found') + (BODY % "We haven't figured out how to do #{error} yet, but shoot us an e-mail and we'll try to get it done!") + SUFFIX
  end
  
  def form_where(vars)
    where = []
    where << " type = '#{vars[:type]}' " if vars[:type]
    #others
    where.join(' and ')
  end
end

##########
# Exceptions
##########

#class NotDoneYet < Exception; end

##########
# Filters
##########

before do
  @db = SQLite3::Database.open(DATABASE_FILE)
end

not_found do 
  not_found_page()
end 

#error do
#  #TODOpass unless env['sinatra.error'].is_a? NotDoneYet
#  not_implemented_page(request.env['sinatra.error'].message) 
#end

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
  if(query_vars.length == 0) #main page
    ret = main_page()
  else #we have some type of operation
    #break it down by operation, then feed the operation the contaminent, time 
    case query_vars[:operation]
    when :count
      ret = count_page('', form_where(query_vars))
    when :histogram
      ret = histogram_page('', form_where(query_vars))
    else
      ret = not_implemented_page()
    end
  end
  ret
end

#/data/?(.*/?){0,6}
#/data(/.*)?
#/data$|/data/(.*/?){1,3}
#/data
#/data/
#/data/1
#/data/1/2/3
#/data/1/2/3/4/5/
#/data/1/2/3/4/5/6
#/data/1/2/3/4/5/6/7
#/data1235

get %r{/data$|/data/(.*/?)} do #':district/:block/:panchayat/:mouza/:hamlet/:well' do
  ret = ''

  if params[:captures] == nil || params[:captures].first.empty?
    ret = table_page()
  else
    url = params[:captures].first
    names = url.split('/')
    geo = {
      :district => names[0],
      :block => names[1],
      :panchayat => names[2],
      :mouza => names[3],
      :hamlet => names[4],
      :code => names[5] #ie well
    }
    #get rid of all nil values
    geo.delete_if do |k,v|
      v == nil
    end
    
    query_vars = process_params(params.reject{|k,v| k.to_sym == :captures })
    #get rid of all nil values
    query_vars.delete_if do |k,v|
      v == nil
    end

    select = query_vars.empty? ? '' : (['date'] + geo.collect{|k,v| "#{k.to_s}"} + [query_vars[:report]]).compact.join(', ' ) #always report date
    where = geo.collect{|k,v| "#{k.to_s} = '#{v.to_s}'"}.join(' and ' )
    group = '' #geo.collect{|k,v| "#{k.to_s}"}.join(', ' )
    #puts "#{select} #{where} #{group}"
    ret = table_page(select, where, group)
  end

  ret
end

get %r{/summary(/|(/[^ /]*){0,7})/?$} do #do up to level of hierarchy
  ret = ''
  hierarchy = [:district, :block, :panchayat, :mouza, :hamlet, :code, :date]
  
  query_vars = process_params(params.reject{|k,v| k.to_sym == :captures })
  #get rid of all nil values
  query_vars.delete_if do |k,v|
    v == nil
  end
  
  if((params[:captures] == nil || params[:captures].first.empty?) && query_vars.length < 1)
    ret = table_links_page(hierarchy, 0, 'district,count(*) as reports', '', 'district')
  else
    names = params[:captures].first.split('/').slice(1..-1) || []#ignore the first one - it's empty
    geo = {#TODO do :all in a level to instead of grouping, display everything below
      :district => names[0],
      :block => names[1],
      :panchayat => names[2],
      :mouza => names[3],
      :hamlet => names[4],
      :code => names[5], #ie well
      :date => names[6] #implicit date level with specific report
    }
    #get rid of all nil values
    geo.delete_if do |k,v|
      v == nil
    end
    
    #p query_vars
    #TODO if count is only one (for all of them?), then we should display the value by default with :report, instead of a count, maybe on :all?
    summary = query_vars[:report] ? ["#{query_vars[:operation] || 'count'}(#{query_vars[:report]})"] : ['count(*) as reports']
    select = geo.length == hierarchy.length && !query_vars[:report]? '' : (hierarchy[0..geo.length].collect{|k,v| "#{k.to_s}"} + summary).compact.join(', ' )
    #:gt only matters when there's a :report? do it as a having?
    #grab the hierarchy except for :all and turn them into key/value pairs
    where = geo.reject{|k,v| v.to_sym == :':all' }.collect{|k,v| "#{k.to_s} = '#{v.to_s}'"}.join(' and ' )
    #decide what level we're at and then display the groups of the next level
    #TODO think I don't want to do one more than geo.length with :all
    group = hierarchy[0..geo.length].collect{|k,v| "#{k.to_s}"}.join(', ' ) #do one more than the current level
    #puts "#{select} #{where} #{group}"
    #TODO is there a way to programatically turn the structured query into prose to do a table description?
    #TODO assuming the below becomes a template, should probably not pass the hierarchy or geo.length, do the processing here
    ret = table_links_page(hierarchy, geo.length, select, where, group)
  end

  ret
end

get '/id/:id' do
  table_page('', "id = #{params[:id]}")
end

get '/dups' do
  html_title = 'Duplicates'

  page_title = '<h1>Duplicates in SMS Water Data (West Bengal)</h2>'
  p1 = "<p>There are currently #{q("select count(*) from (select date,district,block,panchayat,mouza,type,source,hamlet,lab,code,arsenic,tds,salinity,fluoride,iron,tc,fc,ph,hardness,count(*) as count from wb_sms_water group by date,district,block,panchayat,mouza,type,source,hamlet,lab,code,arsenic,tds,salinity,fluoride,iron,tc,fc,ph,hardness having count > 1)").to_i} duplicate entries in the dataset.</p>"
  p2 = "<p class=\"footnote\">If there's more than one, that should be fixed!</p>"
  body = page_title + p1 + p2

  PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
end

get '/repeats' do
  html_title = 'Repeated test sites'

  page_title = '<h1>Duplicates in SMS Water Data (West Bengal)</h2>'
  p1 = "<p>There are currently #{q("select count(*) from (select district,block,panchayat,mouza,hamlet,code,date,count(*) as count from wb_sms_water group by district,block,panchayat,mouza,hamlet,code,date) where count > 1").to_i} repeated sites in the dataset.</p>"
  p2 = "<p class=\"footnote\">For an example, dig into the <a href=\"/data\">data</a>.</p>"
  body = page_title + p1 + p2

  PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
end

#get '/gt/:level' do #greater than
#  
#end

#get '/correleation/'
#...

#get 'data/:district/:block/:panchayat/:mouza/:hamlet/:well/:type/:report/:time/:operation' do ||
#do /:district/:block/:panchayat/:mouza/:hamlet/:well?:type&:report&:time&:operation

#html_title = ''
#page_title = ''
#
#body = page_title + ...
#
#PREFIX + (HEAD % html_title) + (BODY % body) + SUFFIX
#
