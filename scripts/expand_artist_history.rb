# frozen_string_literal: true

require 'bundler/setup'
require 'git'
require 'json'
require 'date'

def main
  git = Git.open('.')

  artist_id = ARGV.first
  input_path = "output/#{artist_id}.json"
  output_path = "output/history_#{artist_id}.json"

  history = git.log(1000).path(input_path).map do |item|
    historical_object = JSON.parse(git.show(item.sha, input_path))

    timestamp = time_to_date(item.date)
    historical_object[:timestamp] = timestamp.iso8601

    historical_object
  end

  File.write(output_path, JSON.pretty_generate(history))
  puts("Saved history for #{artist_id} to #{output_path}")
end

def time_to_date(time)
  DateTime.new(time.year, time.month, time.day, time.hour, time.min, time.sec,
               Rational(time.gmt_offset / 3600, 24))
end

main
