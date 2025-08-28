# frozen_string_literal: true

# rubocop:disable Style/GlobalVars

require 'bundler/setup'
require 'sqlite3'
require 'date'
require 'json'
require 'rest-client'
require 'rspotify'
require_relative 'db_utils'
require_relative 'date_utils'

MAX_RETRIES = 25

$db = SQLite3::Database.new('spotify-data.db')
$db.results_as_hash = true
$timestamp = round_time(Time.now).to_i

def main

  create_artist_ids_table($db)
  create_artist_snapshots_table($db)
  seed_initial_artist_ids($db)

  authenticate

  artist_ids = read_artist_ids

  bulk_insert($db, artist_ids, method(:find_and_generate_artist_snapshot_commands), 50, 500)
end

def find_and_generate_artist_snapshot_commands(artist_ids_chunk)
  artists = RSpotify::Artist.find(artist_ids_chunk).compact

  artists.map { |artist| generate_insert_artist_snapshot_command(artist) }
end

def generate_insert_artist_snapshot_command(artist)
  row = [artist.id, $timestamp, artist.popularity, artist.followers['total']]
  ['INSERT OR IGNORE INTO artist_snapshots (id, timestamp, popularity, followers) VALUES (?, ?, ?, ?);', row]
end

def read_artist_ids
  $db.results_as_hash = false
  total = $db.execute('SELECT COUNT(id) FROM artist_ids;')[0][0]
  $db.results_as_hash = true
  chunk_size = (total / 24).floor
  puts "artist_ids total #{total} chunk_size #{chunk_size}"
  limit = chunk_size
  offset = chunk_size * current_hour_index
  artist_id_rows = $db.execute('SELECT id FROM artist_ids LIMIT ? OFFSET ?;', [limit, offset])
  artist_id_rows.map { |row| row['id'] }
end

def authenticate(index = nil, attempt = 1)
  client_ids = ENV['CLIENT_IDS'].split(',')
  client_secrets = ENV['CLIENT_SECRETS'].split(',')

  secret_index = !index.nil? ? index : current_hour_index % 8

  client_id = client_ids.at(secret_index) || client_ids.first
  client_secret = client_secrets.at(secret_index) || client_secrets.first

  RSpotify.authenticate(client_id, client_secret)
rescue RestClient::TooManyRequests, RestClient::ServiceUnavailable, RestClient::InternalServerError,
  RestClient::GatewayTimeout, RestClient::BadGateway, RestClient::Unauthorized
  max_sleep_seconds = Float(2**attempt)
  sleep rand(0.0..max_sleep_seconds)
  authenticate(index, attempt + 1) if attempt < MAX_RETRIES
end

main

# rubocop:enable Style/GlobalVars
