#!/usr/bin/env ruby

# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'net/https'
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'colorize'
  gem 'nokogiri'
end

class HLTB
  URL = 'https://howlongtobeat.com/search_results?page=1'

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
      'Accept'       => '*/*',
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Origin'       => 'https://howlongtobeat.com',
      'Referer'      => 'https://howlongtobeat.com/',
      'User-Agent'   => user_agent
    }
  end

  # rubocop:disable Layout/LineLength
  def user_agent
    [
      # Brave + Chrome
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36',
      # Safari
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.2 Safari/605.1.15',
      # Firefox
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:96.0) Gecko/20100101 Firefox/96.0'
    ].sample
  end
  # rubocop:enable Layout/LineLength

  def form_data
    {
      queryString: game,
      t:           'games',
      sorthead:    'popular',
      sortd:       'Normal Order',
      plat:        nil,
      length_type: 'main',
      length_min:  nil,
      length_max:  nil,
      detail:      nil
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

  def games
    details.map {|d| extract d }
  end

  private

  attr_reader :game

  def extract(data)
    {
      path:  data.css('a').first.attributes['href'].value,
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
      hash[type] = string_to_time(time_section.shift.children.text) if time_section.any?
    end
  end

  def types
    %i[main extra complete]
  end

  def string_to_time(string)
    if string.include? 'Mins'
      extract_time string, 'Mins'
    else
      extract_time string, 'Hours'
    end
  end

  def extract_time(string, unit_string)
    time = { duration: 1.0, units: '' }

    time[:units] = unit_string.include?('Mins') ? 'minute' : 'hour'
    time[:duration] = string.gsub(unit_string, '').gsub('½', '.5').strip.to_f

    # convert to integer if there is no value after the decimal
    time[:duration] = time[:duration].round if time[:duration].to_i == time[:duration]

    # pluralize units if unit > 1
    time[:units] += 's' if time[:duration] > 1

    time
  end

  def response
    @response ||= HLTB.new(game).response
  end

  def details
    @details ||= page.css('.search_list_details')
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

game_name = ARGV.join(' ')
lookup = GameLookup.new(game_name)
unless lookup.valid?
  puts "#{lookup.code} response code received"
  exit 2
end

lookup.games.each_with_index do |game, i|
  puts "#{i + 1}: #{game[:title]}".light_blue
  puts "Link: https://howlongtobeat.com/#{game[:path]}".cyan
  game[:times].each do |type, time|
    puts "#{type.to_s.capitalize}: #{time[:duration]} #{time[:units]}"
  end
  puts '' unless lookup.games.size == i+1
end
