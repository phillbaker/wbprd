require 'sinatra/base'
# my_sinatra_app.rb
class MySinatraApp < Sinatra::Application
  
  get '/*' do
    'Falalala'
  end
  
end