# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'sqlite3'
require 'date'
require 'json'
require 'rest-client'
require 'rspotify'
require_relative 'spotify_utils'
require_relative 'storage_utils'
require_relative 'db_utils'
require_relative 'date_utils'

@db_name = db_name
@db = SQLite3::Database.new(@db_name)
@artist_ids_db = pull_or_instantiate_artist_ids_db
@db.results_as_hash = true
@timestamp = rounded_current_timestamp

def main
  create_artist_snapshots_table(@db)

  authenticate

  artist_ids = read_artist_ids

  bulk_insert(@db, artist_ids, method(:find_and_generate_artist_snapshot_commands))
end

def find_and_generate_artist_snapshot_commands(artist_ids_chunk, attempt = 1, max_retries = 25)
  artists = RSpotify::Artist.find(artist_ids_chunk).compact

  artists.map { |artist| generate_insert_artist_snapshot_command(artist) }
rescue RestClient::TooManyRequests, RestClient::ServiceUnavailable, RestClient::InternalServerError,
  RestClient::GatewayTimeout, RestClient::BadGateway, RestClient::Unauthorized
  max_sleep_seconds = Float(2**attempt)
  sleep rand(0.0..max_sleep_seconds)
  find_and_generate_artist_snapshot_commands(artist_ids_chunk, attempt + 1) if attempt < max_retries
end

def generate_insert_artist_snapshot_command(artist)
  row = [artist.id, @timestamp, artist.popularity, artist.followers['total']]
  ['INSERT OR IGNORE INTO artist_snapshots (id, timestamp, popularity, followers) VALUES (?, ?, ?, ?);', row]
end

def read_artist_ids
  @artist_ids_db.results_as_hash = false
  total = @artist_ids_db.get_first_value('SELECT COUNT(id) FROM artist_ids;')
  @artist_ids_db.results_as_hash = true
  chunk_size = (total / 24).floor
  puts "db_name #{db_name} timestamp #{@timestamp} artist_ids total #{total} chunk_size #{chunk_size}"
  limit = chunk_size
  offset = chunk_size * current_hour_index
  artist_id_rows = @artist_ids_db.execute('SELECT id FROM artist_ids LIMIT ? OFFSET ?;', [limit, offset])
  artist_id_rows.map { |row| row['id'] }
end

main
