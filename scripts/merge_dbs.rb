# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'sqlite3'
require_relative 'db_utils'
require_relative 'storage_utils'

@target_db = SQLite3::Database.new('merged-spotify-data.db')
@target_db.results_as_hash = true

def main
  create_artist_snapshots_table(@target_db)

  source_db_filenames = Dir.glob('spotify-data*.db')
  source_db_filenames.each do |source_db_filename|
    source_db = SQLite3::Database.new(source_db_filename)
    source_db.results_as_hash = true

    source_records = source_db.execute <<-SQL
        SELECT * FROM artist_snapshots;
    SQL

    bulk_insert(@target_db, source_records, method(:generate_insert_artist_snapshot_commands))
  end
end

def generate_insert_artist_snapshot_commands(artists)
  artists.map { |artist| generate_insert_artist_snapshot_command(artist) }
end

def generate_insert_artist_snapshot_command(artist)
  row = [artist['id'], artist['timestamp'], artist['popularity'], artist['followers']]
  ['INSERT OR IGNORE INTO artist_snapshots (id, timestamp, popularity, followers) VALUES (?, ?, ?, ?);', row]
end

main
