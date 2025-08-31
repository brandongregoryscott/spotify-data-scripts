# frozen_string_literal: true

require 'bundler/setup'
require 'sqlite3'
require_relative 'db_utils'

@db_name = db_name
@db = SQLite3::Database.new(@db_name)
@db.results_as_hash = true

def main
  @db.execute <<-SQL
    ALTER TABLE artists RENAME TO artist_ids;
  SQL

  @db.execute <<-SQL
    ALTER TABLE artist_ids DROP COLUMN name;
  SQL

  @db.execute <<-SQL
    DROP TABLE git_history;
  SQL
end

main
