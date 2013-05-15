require 'sinatra'
require 'coffee-script'

set :haml, format: :html5

get '/' do
  haml :index
end

get "/application.js" do
  coffee :application
end

get '/application.css' do
  sass :application
end
