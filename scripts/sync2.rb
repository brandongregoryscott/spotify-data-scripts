# frozen_string_literal: true
#
require 'bundler/setup'
require 'sqlite3'
require 'date'
require 'json'
require 'rest-client'

MAX_RETRIES = 25

$db = SQLite3::Database.new('spotify-data.db')
$db.results_as_hash = true

def main

  create_artist_ids_table
  create_artist_snapshots_table
  seed_initial_artist_ids

end

def create_artist_ids_table
  $db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS artist_ids (
      id TEXT PRIMARY KEY
    );
  SQL
end

def create_artist_snapshots_table
  $db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS artist_snapshots (
      id TEXT,
      timestamp NUMERIC,
      followers NUMERIC,
      popularity NUMERIC,
      UNIQUE (id, timestamp)
    );
  SQL
end

def seed_initial_artist_ids
  $db.execute <<-SQL
    INSERT INTO artist_ids (id) VALUES ('6lcwlkAjBPSKnFBZjjZFJs');
  SQL
rescue SQLite3::ConstraintException
  nil
end

main
