# frozen_string_literal: true
#
require 'bundler/setup'
require 'sqlite3'
require 'date'
require 'json'

MAX_RETRIES = 25

def main
  db = SQLite3::Database.new('spotify-data.db')
  db.results_as_hash = true

  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS artist_ids (
      id TEXT PRIMARY KEY
    );
  SQL

  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS artists (
      id TEXT PRIMARY KEY,
      name TEXT
    );
  SQL

  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS artist_snapshots (
      id TEXT,
      timestamp NUMERIC,
      followers NUMERIC,
      popularity NUMERIC,
      UNIQUE (id, timestamp)
    );
  SQL

end

main