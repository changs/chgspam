#!/usr/bin/ruby

require "rubygems"
require "bundler/setup"

require 'anemone'
require 'nokogiri'

domain = ARGV[0]
email_regex = /[\w+\-.]+@[a-z\d\-.]+\.[a-z]+/i
arr_mails = Array.new

Anemone.crawl(domain) do |anemone|
  
  anemone.focus_crawl do |page|
    page.links.select! do |x|
      x.to_s.downcase.include? domain.downcase
    end
  end

  anemone.on_every_page do |page|
    puts page.url
    mails = page.body.scan(email_regex)
    mails.each do |mail|
      arr_mails.push(mail) unless arr_mails.index(mail) 
    end    
  end
end

puts "Emails found in #{domain}"
puts arr_mails
