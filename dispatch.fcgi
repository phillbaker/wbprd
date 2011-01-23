#!/kunden/homepages/41/d212428667/htdocs/lumin_wbprd/bin/ruby

begin
  require 'rubygems'
  require 'rack'
  require 'fcgi'
  require 'sinatra/base'

  # my_sinatra_app.rb
  class MySinatraApp < Sinatra::Application
    get '/*' do
      'Falalala'
    end
  end

  app = Proc.new do |env|
    [200, {'Content-type' => 'text/plain'}, 'helloworld']
  end

  Rack::Handler::CGI.run(MySinatraApp)
rescue Exception => e
  puts "Content-type: text/plain \n\n #{e}"
  puts e.class.to_s
  puts e.backtrace
end

