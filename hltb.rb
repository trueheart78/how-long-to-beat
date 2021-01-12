#!/usr/bin/env ruby

require 'open-uri'
require 'cgi'
require 'nokogiri'

if ARGV.empty?
  puts 'please enter a game name'
  exit 1
end

game = ARGV.shift
search = Nokogiri::HTML(open("https://duckduckgo.com/html?q=site%3Ahowlongtobeat.com+#{CGI.escape(game)}"))
hltb_url = CGI.unescape search.css('.result__title').first.to_s.match(/(https%3A%2F%2Fhowlongtobeat.com%2Fgame.php%3Fid%3D\d+)"/)[1]
page = Nokogiri::HTML(open(hltb_url))
displayed_game = page.css('.profile_header').text.strip
times = page.css('.game_times').map { |e| e.text.gsub('Hours','').gsub('½','').split("\n").map(&:strip).reject(&:empty?) }.flatten.map(&:strip).select { |e| e.to_i.to_s == e }.map(&:to_i)
hours = { main: times[0], plus_extras: times[1], completionist: times[2] }

puts hltb_url
puts displayed_game
hours.each do |k, v|
  puts "#{k}: #{v} hours"
end
