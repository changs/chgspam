require 'sinatra'
require 'data_mapper'

get '/' do
  'Hello world!'
end

get '/start' do
  content_type :json
  { :domain => 'http://www.put.poznan.pl/', :key2 => 'value2' }.to_json
end

post '/email' do
  c = JSON.parse(request.body.read)
  puts "Received: #{c}"
end
