require 'rubygems'
require 'httparty'
#require ''

#http://72.26.224.173/water/Default.aspx

class Google
  include HTTParty
  include HTTParty
  format :html
  http_proxy '10.20.0.1', 8080
end

puts Google.get('http://google.com')
