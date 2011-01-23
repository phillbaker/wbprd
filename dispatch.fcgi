#!/kunden/homepages/41/d212428667/htdocs/lumin_wbprd/bin/ruby

begin
  require 'rubygems'
  #ENV['GEM_PATH'] ||= '/kunden/homepages/41/d212428667/htdocs/lumin_wbprd/lib/ruby/gems/1.8'
  #ENV['GEM_HOME'] ||= '/kunden/homepages/41/d212428667/htdocs/lumin_wbprd/lib/ruby/gems/1.8'
  require 'rack'
  require 'fcgi'
  require 'sinatra/base'

module Rack
  module Handler
    class FastCGI
      def self.run(app, options={})
        if options[:File]
          STDIN.reopen(UNIXServer.new(options[:File]))
        elsif options[:Port]
          STDIN.reopen(TCPServer.new(options[:Host], options[:Port]))
        end
        FCGI.each_cgi { |request|
	  #request.instance_eval('alias :env :env_table; alias :in :stdinput; alias :out :stdoutput')
          request.instance_eval('def env; h = {}; env_table.each{|k,v| h[k] = v}; h; env_table; end; def in; stdinput; end; def out; stdoutput; end; def err; ""; end')
	  #FCGI::Request.new(request.env_table)
	  #begin
	    serve request, app
	  #rescue Exception => e
	  #  puts "Content-type: text/plain \n\n #{e}"
	  #  puts e.backtrace
	  #end
        }
      end
    end
  end
end

  app = Proc.new do |env|
    #puts "here"
    [200, {'Content-type' => 'text/plain'}, 'helloworld']
  end

#FCGI.class_eval('alias :each :each_cgi; alias :env :env_table')

#  puts "Content-type: text/plain \n\n"
  #FCGI.each {|req| req.out = STDOUT }
  Rack::Handler::CGI.run(app)
  #Rack::Handler::FastCGI.run(app)
  #app.call
  #puts FCGI.is_cgi?
  #FCGI.each_cgi {|req| puts req.env_table.class.to_s }
  #FCGI.each { |request|
  #   puts 'there'
  #   status, headers, body = app.call(env)
  #   STDOUT.print body
  #}
rescue Exception => e
  puts "Content-type: text/plain \n\n #{e}"
  puts e.class.to_s
  puts e.backtrace
ensure
  cgi_str = ''
  #FCGI.each {|req| puts req.out.inspect.to_s }
  FCGI.each_cgi {|cgi| cgi_str << cgi.env_table.inspect.to_s.gsub(/", "/, "\", \n \"") }
  puts "Content-type: text/plain \n\n end #{Time.now.to_s} \n #{cgi_str}"
end

