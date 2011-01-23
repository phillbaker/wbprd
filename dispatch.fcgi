#!/kunden/homepages/41/d212428667/htdocs/lumin_wbprd/bin/ruby

begin
  require 'rubygems'
  require 'rack'
  #require 'application.rb'
  require 'sinatra/base'
  
  module Rack
    class Request
      def path_info
        @env["SCRIPT_URL"].to_s
      end
      def path_info=(s)
        @env["SCRIPT_URL"] = s.to_s
      end
    end
  end
  
  class MySinatraApp < Sinatra::Application
    get '/' do
      'home'
    end
    
    get '/*' do
      pass if params[:splat].empty?
      'hello!'
    end
  end
  
  builder = Rack::Builder.new do
    #use Rack::CommonLogger
    #use Rack::ShowExceptions
    
    map '/' do
      #env['PATH_INFO'] = env['SCRIPT_URL']
      run MySinatraApp.new
    end
  end

  Rack::Handler::CGI.run(builder)
  #require 'fcgi'
  #cgi_str = ''
  #FCGI.each_cgi {|cgi| cgi_str << cgi.env_table.inspect.to_s.gsub(/", "/, "\", \n \"") }
  #puts "Content-type: text/plain \n\n end #{Time.now.to_s} \n #{cgi_str}"
rescue Exception => e
  puts "Content-type: text/plain \n\n #{e}"
  puts e.class.to_s
  puts e.backtrace
end

