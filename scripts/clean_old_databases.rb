# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'aws-sdk-s3'
require_relative 'storage_utils'

def main
  databases = list_databases_desc
  puts("Found #{databases.length} databases...")
  return if databases.length < 2

  # Select all but the first database, which is the most recently uploaded
  databases_to_delete = databases.drop(1).map { |db| { key: db[:key] } }

  puts("Deleting #{databases_to_delete.length} databases...")

  @r2.delete_objects({ bucket: 'spotify-data', delete: { objects: databases_to_delete, quiet: false } })

  puts("Deleted #{databases_to_delete.length} databases!")
end

main
