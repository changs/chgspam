#!/usr/bin/ruby

require "rubygems"
require "bundler/setup"

require 'anemone'
require 'nokogiri'
require 'rest_client'
require 'json'
require 'set'

email_regex = /[\w+\-.]+@[a-z\d\-.]+\.[a-z]+/i
email_regex2 = /([\w+\-.]+) \[ at \] ([a-z\d\-.]+\.[a-z]+)/i

server_url = 'http://127.0.0.1:4567'
response = RestClient.get server_url + '/start'
params = JSON.parse(response)
domain = params["domain"]
arr_mails = Set.new
out_links = Array.new
links = Set.new

Anemone.crawl(domain) do |anemone|

  anemone.focus_crawl do |page|
    domain_links = page.links.select do |x|
      x.to_s.downcase.include? domain.downcase
    end
    out_links = out_links + page.links - domain_links
    domain_links
  end

  anemone.user_agent = "ChgCrawler"
  anemone.on_every_page do |page|
    puts page.url
    next unless page.html? 
    page.doc.search("//a[@href]").each do |a|
      u = a['href']
      next if u.nil? or u.empty?
      abs = page.to_absolute(URI(u)) rescue next
      links << abs.to_s unless page.in_domain?(abs)
    end

    mails = page.body.scan(email_regex)
    mails.each { |mail| arr_mails.add(mail) }
    mails = page.body.scan(email_regex2)  # $1 is a content before @, $2 after.
    mails.each { |mail| arr_mails.add($1 + '@' + $2) }

  end
end

puts "Links: #{links.to_a}"
puts "Emails found in #{domain}"

RestClient.post server_url + '/email', 
  { 'emails' => arr_mails.to_a }.to_json, :content_type => :json, :accept => :json

RestClient.post server_url + '/links', 
  { 'links' => links_to_a }.to_json, content_type: :json, accept: :json

p arr_mails.to_a


