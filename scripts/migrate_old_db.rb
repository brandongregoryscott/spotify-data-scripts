# frozen_string_literal: true

require 'bundler/setup'
require 'sqlite3'
require_relative 'db_utils'

@db_name = db_name
@db = SQLite3::Database.new('_spotify-data_1751481126928.db')
@db.results_as_hash = true

def main
  @db.execute <<-SQL
    DROP TABLE artists;
  SQL

  @db.execute <<-SQL
    DROP TABLE git_history;
  SQL

  @db.execute <<-SQL
    VACUUM;
  SQL
end

main
