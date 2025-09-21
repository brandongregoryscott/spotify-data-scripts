# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'aws-sdk-s3'
require_relative 'storage_utils'

def main
  dbs = list_databases_desc

  dbs.each { |db| @r2.get_object({ bucket: 'spotify-data', key: db.key }, target: db.key) }
end

main
