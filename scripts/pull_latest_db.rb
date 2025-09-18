# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'aws-sdk-s3'
require_relative 'storage_utils'

def main
  last_uploaded_db = list_databases_desc.first

  puts("Downloading #{last_uploaded_db.key}...")

  @r2.get_object({ bucket: 'spotify-data', key: last_uploaded_db.key }, target: last_uploaded_db.key)

  puts("Downloaded #{last_uploaded_db.key}!")
end

main
