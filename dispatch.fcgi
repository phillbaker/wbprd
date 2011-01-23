#!/kunden/homepages/41/d212428667/htdocs/lumin_wbprd/bin/ruby

begin
  require 'rubygems'
  require 'rack'
  require 'fcgi'
  require 'application.rb'

  Rack::Handler::CGI.run(MySinatraApp)
rescue Exception => e
  puts "Content-type: text/plain \n\n #{e}"
  puts e.class.to_s
  puts e.backtrace
end

