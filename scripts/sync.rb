# frozen_string_literal: true

require 'bundler/setup'
require 'json'
require 'rspotify'
require 'date'
require 'rest-client'

MAX_RETRIES = 25

def main
  authenticate

  artist_ids = read_artists_json_file
  chunk = chunk_artist_ids_by_current_hour(artist_ids)

  chunk.each_slice(50) do |artist_ids_chunk|
    find_and_save_artists(artist_ids_chunk)
  end
end

def find_and_save_artists(artist_ids_chunk, attempt = 1)
  artists = RSpotify::Artist.find(artist_ids_chunk).compact
  artists.each do |artist|
    save_artist_json_file(artist)
  end
rescue RestClient::TooManyRequests, RestClient::ServiceUnavailable, RestClient::InternalServerError,
  RestClient::GatewayTimeout, RestClient::BadGateway, RestClient::Unauthorized
  max_sleep_seconds = Float(2**attempt)
  sleep rand(0..max_sleep_seconds)
  authenticate(rand(0..7))
  find_and_save_artists(artist_ids_chunk, attempt + 1) if attempt < MAX_RETRIES
end

def authenticate(index = nil, attempt = 1)
  client_ids = ENV['CLIENT_IDS'].split(',')
  client_secrets = ENV['CLIENT_SECRETS'].split(',')

  secret_index = !index.nil? ? index : current_hour % 8

  client_id = client_ids.at(secret_index) || client_ids.first
  client_secret = client_secrets.at(secret_index) || client_secrets.first

  RSpotify.authenticate(client_id, client_secret)
rescue RestClient::TooManyRequests, RestClient::ServiceUnavailable, RestClient::InternalServerError,
       RestClient::GatewayTimeout, RestClient::BadGateway, RestClient::Unauthorized
  max_sleep_seconds = Float(2**attempt)
  sleep rand(0..max_sleep_seconds)
  authenticate(index, attempt + 1) if attempt < MAX_RETRIES
end

def current_hour
  # - flag drops then padding
  hour = DateTime.now.strftime('%-H')
  Integer(hour)
end

def read_artists_json_file
  artist_ids_file = File.read('input/artists.json')
  JSON.parse(artist_ids_file)
end

def chunk_artist_ids_by_current_hour(artist_ids)
  puts "artist_ids.length #{artist_ids.length}"
  chunk_size = (artist_ids.length / 24).floor
  puts "chunk_size #{chunk_size}"
  artist_ids.each_slice(chunk_size).to_a.at(current_hour)
end

def save_artist_json_file(artist)
  File.write("output/#{artist.id}.json", json_stringify_artist(artist))
end

def json_stringify_artist(artist) # rubocop:disable Metrics/MethodLength
  artist_object = {
    'id' => artist.id,
    'name' => artist.name,
    'uri' => artist.uri,
    'followers' => artist.followers,
    'genres' => artist.genres,
    'images' => artist.images,
    'popularity' => artist.popularity,
    'external_urls' => artist.external_urls
  }
  JSON.fast_generate(artist_object)
end

main
