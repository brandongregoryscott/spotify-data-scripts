# frozen_string_literal: true

require 'bundler/setup'
require 'sqlite3'
require_relative 'db_utils'

@db_name = db_name
@db = SQLite3::Database.new(@db_name)
@trimmed_db = SQLite3::Database.new('trimmed-db.db')
@db.results_as_hash = true

def main
  create_artist_ids_table(@trimmed_db)
  create_artist_snapshots_table(@trimmed_db)

  @trimmed_db.execute <<-SQL
    INSERT OR IGNORE INTO artist_ids (id) VALUES  ('6lcwlkAjBPSKnFBZjjZFJs');
  SQL

  @trimmed_db.execute <<-SQL
    INSERT OR IGNORE INTO artist_ids (id) VALUES  ('5AyEXCtu3xnnsTGCo4RVZh');
  SQL

  snapshots = @db.execute <<-SQL
    SELECT * FROM artist_snapshots WHERE id IN ('6lcwlkAjBPSKnFBZjjZFJs', '5AyEXCtu3xnnsTGCo4RVZh') ORDER BY timestamp ASC;
  SQL

  bulk_insert(@trimmed_db, snapshots, method(:generate_insert_artist_snapshot_commands))
end

def generate_insert_artist_snapshot_commands(snapshots)
  snapshots.map { |snapshot| generate_insert_artist_snapshot_command(snapshot) }
end

def generate_insert_artist_snapshot_command(snapshot)
  row = [snapshot['id'], snapshot['timestamp'], snapshot['popularity'], snapshot['followers']]
  ['INSERT OR IGNORE INTO artist_snapshots (id, timestamp, popularity, followers) VALUES (?, ?, ?, ?);', row]
end

main

