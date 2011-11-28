#!/usr/bin/ruby

require "rubygems"
require "bundler/setup"

require 'anemone'
require 'nokogiri'
require 'rest_client'
require 'json'
require 'set'

def meta_refresh?(page)
  if redirect_url = page.doc.at('meta[http-equiv="Refresh"]')
  else redirect_url = page.doc.at('meta[http-equiv="refresh"]')
  end
  url = redirect_url['content'][/url=(.+)/, 1] unless redirect_url.nil?
end

def send_to_server(server_url, params)
  RestClient.post server_url, params.to_json, :content_type => :json, :accept => :json
end

email_regex = /[\w+\-.]+@[a-z\d\-.]+\.[a-z]+/i
email_regex2 = /([\w+\-.]+) \[ at \] ([a-z\d\-.]+\.[a-z]+)/i

if (ARGV[0].nil?) 
  puts "Usage: crawler.rb [server_url]"
  exit
end

server_url = ARGV[0]
puts "Connecting to #{server_url}."
while true
begin 
  response = RestClient.get server_url + '/start'
rescue => e
  puts e
  exit
end

params = JSON.parse(response)
if params["domain"].nil?
  puts "Nothing to do."
  exit
end

domain = params["domain"]['url']
arr_mails = Set.new
links = Set.new

puts "Crawling on #{domain}"

Anemone.crawl(domain) do |anemone|
#  anemone.storage = Anemone::Storage.MongoDB
  anemone.focus_crawl do |page|
    page.links.select do |x|
      x.to_s.downcase.include? domain.downcase
    end
    page.links.slice(0..500)
  end
  
  anemone.user_agent = "ChgCrawler"
  anemone.on_every_page do |page|
    print "." #page.url

    next unless page.html?
    if meta_refresh?(page)
      links << meta_refresh?(page)
      next
    end

    page.doc.search("//a[@href]").each do |a|
      u = a['href']
      next if u.nil? or u.empty?
      abs = page.to_absolute(URI(u)) rescue next
      links << abs.to_s unless page.in_domain?(abs)
    end

    mails = page.body.scan(email_regex)
    mails.each { |mail| arr_mails.add(mail) }
    mails = page.body.scan(email_regex2)  # $1 is a content before @, $2 after.
    mails.each { |mail| arr_mails.add(mail[0] + '@' + mail[1]) }
  end
end

puts
puts "Found #{links.length} links."
puts "Found #{arr_mails.length} emails."

x = 0
mails = arr_mails.to_a
while x < mails.count-10
  send_to_server(server_url + '/email', { 'emails' => mails[x...x+10], 'domain' => domain })
  x+=10
end
send_to_server(server_url + '/email', { 'emails' => mails[x...mails.count], 'domain' => domain })

x = 0
alinks = links.to_a
while x < alinks.count-10
  send_to_server(server_url + '/link',  { 'url' => alinks[x...alinks.count ]})
  x+=10
end
send_to_server(server_url + '/link',  { 'url' => alinks[x...alinks.count]})

puts "Sleep for a while" 
sleep 5
end
