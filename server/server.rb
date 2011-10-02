require 'sinatra'
require 'data_mapper'
require 'haml'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/database.db")

class Email
  include DataMapper::Resource
  property :id, Serial
  property :url, String
end

class Domain
  include DataMapper::Resource
  property :id, Serial
  property :url, String
  property :visited, Boolean
  property :visited_at, DateTime
end

DataMapper.finalize
Email.auto_migrate! unless Email.storage_exists?
Domain.auto_migrate! unless Domain.storage_exists?

configure do
  Domain.destroy
  Email.destroy
  Domain.create(url: "http://127.0.0.1:4567", visited: false, visited_at: Time.now-6000)
end

get '/' do
  'Hello world! <a href="/test">Link</a> <a href="http://www.put.poznan.pl">Polibuda</a>'
end

get '/start' do
  failed = Domain.all(visited: false, :visited_at.lt => (Time.now-600)) # Wait for 10 minutes for crawlers to return
  failed.each { |x| x.update(visited_at: nil) }
    content_type :json
  if domain = Domain.first(visited_at: nil)
  else  # If nothing lefts return the oldest domain to crawl
    domain = Domain.first(visited_at: Domain.min(:visited_at))
  end
  domain.update(visited_at: Time.now)
  { domain: domain }.to_json
end

post '/email' do
  c = JSON.parse(request.body.read)
  addresses = c["emails"]
  addresses.each { |x| Email.first_or_create(url: x) }
  visited = Domain.first(url: c["domain"])
  visited.update(visited: true)
end

post '/link' do
  c = JSON.parse(request.body.read)
  links = c["url"]
  links.each { |x| Domain.first_or_create(url: x) }
end

get '/link' do
  @items = Domain.all
  haml :items
end

get '/email' do
  @items = Email.all
  haml :items
end

get '/test' do
  "bartosz@pranczke.com ala@wp.pl fdsfsd@das.com"
end

__END__

@@ layout
%html
  %body= yield

@@ items
%h2== #{@items.count} gathered addresses.
- @items.each do |i|
  %p= i['url']