#!/usr/bin/env ruby

# frozen_string_literal: true

require 'open-uri'
require 'cgi'
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'nokogiri'
end

if ARGV.empty?
  puts 'please enter a game name'
  exit 1
end

game = ARGV.shift
search = Nokogiri::HTML(URI.parse("https://duckduckgo.com/html?q=site%3Ahowlongtobeat.com+#{CGI.escape(game)}").open)
match = /(https%3A%2F%2Fhowlongtobeat.com%2Fgame.php%3Fid%3D\d+)/
hltb_url = CGI.unescape search.css('.result__title').first.to_s.match(match)[1]
page = Nokogiri::HTML(URI.parse(hltb_url).open)
displayed_game = page.css('.profile_header').text.strip
times = page.css('.game_times').map do |e|
  e.text.gsub('Hours', '').gsub('½', '').split("\n").map(&:strip).reject(&:empty?)
end

times = times.flatten.map(&:strip).select {|e| e.to_i.to_s == e }.map(&:to_i)
hours = { main: times[0], plus_extras: times[1], completionist: times[2] }

puts hltb_url
puts displayed_game
hours.each do |k, v|
  puts "#{k}: #{v} hours"
end
