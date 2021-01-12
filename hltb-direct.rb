#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'net/https'
require 'nokogiri'

class HLTB
  URL = 'https://howlongtobeat.com/search_results?page=1'.freeze

  def initialize(game)
    @game = game
	end

  def response
    @response ||= https.request post_request
  end

  private

  attr_reader :game

  def post_request
    Net::HTTP::Post.new(uri.path, headers).tap do |request|
      request.set_form_data form_data
    end
  end

  def https
    Net::HTTP.new(uri.host, uri.port).tap do |x|
      x.use_ssl = true
    end
  end

  def uri
    @uri ||= URI.parse URL
  end

  def headers
    {
      'Accept' => '*/*',
      #'Accept-Encoding' => 'gzip, deflate, br',
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Origin' => 'https://howlongtobeat.com',
      'Referer' => 'https://howlongtobeat.com/',
      'User-Agent' => user_agent
    }
  end

  def user_agent
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.186 Safari/537.36'
  end

  def form_data
    {
      queryString: game,
      t: 'games',
      sorthead: 'popular',
      sortd: 'Normal Order',
      plat: nil,
      length_type: 'main',
      length_min: nil,
      length_max: nil,
      detail: nil
    }
  end
end

class GameLookup
  def initialize(game)
    @game = game
  end

  def valid?
    response.code.start_with? '2'
  end

  def code
    response.code
  end

  def matches
    return 0 unless valid?
    games.size
  end

  def details
    games.map { |d| extract d }
  end

  private

  attr_reader :game

  def extract(data)
    {
      path: data.css('a').first.attributes['href'].value,
      title: data.css('a').first.attributes['title'].value,
      times: times(data)
    }
  end

  def times_section(data)
    return '.search_list_tidbit' if data.css('.search_list_tidbit').any?
    return '.search_list_tidbit_long' if data.css('.search_list_tidbit_long').any?
    nil
  end

  def times(data)
    return {} unless times_section(data)
    time_section = data.css(times_section(data)).css('.center')
    types.each_with_object({}) do |type, hash|
      hash[type] = sanitize(time_section.shift.children.text) if time_section.any?
    end
  end

  def types
    %i(main extra complete)
  end

  def sanitize(string)
    string.gsub('Hours', '').gsub('½','.5').strip.to_f.tap do |hours|
      hours = hours.round if hours.to_i == hours
    end
  end

  def response
    @response ||= HLTB.new(game).response
  end

  def games
    @games ||= page.css('.search_list_details')
  end

  def page
    return unless valid?
    @page ||= Nokogiri::HTML(response.body)
  end
end

if ARGV.empty?
  puts 'Error: no game name provided'
  exit 1
end

lookup = GameLookup.new(ARGV.first)
unless lookup.valid?
  puts "#{lookup.code} response code received"
  exit 2
end

lookup.details.each_with_index do |game, i|
  puts "#{i+1}: #{game[:title]}"
  puts game[:path]
  game[:times].each do |type, hours|
    puts "#{type.to_s.capitalize}: #{hours} hours"
  end
  puts ''
end
