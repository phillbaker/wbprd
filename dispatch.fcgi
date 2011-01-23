#!/kunden/homepages/41/d212428667/htdocs/lumin_wbprd/bin/ruby

begin
  require 'rubygems'
  require 'rack'
  require 'application.rb'
  
  module Rack
    class Request
      def path_info
        @env['SCRIPT_URL'].to_s
      end
      def path_info=(s)
        @env['SCRIPT_URL'] = s.to_s
      end
    end
  end
  
  builder = Rack::Builder.new do
    #use Rack::CommonLogger
    #use Rack::ShowExceptions
    
    map '/' do
      run WbprdStats.new
    end
  end

  Rack::Handler::CGI.run(builder)
rescue Exception => e
  puts "Content-type: text/plain \n\n #{e}"
  puts e.class.to_s
  puts e.backtrace
end

