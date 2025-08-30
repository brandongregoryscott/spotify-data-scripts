# frozen_string_literal: true

require 'bundler/setup'
require 'aws-sdk-s3'
require_relative 'storage_utils'

def main
  database_objects = @r2.list_objects(bucket: 'spotify-data', max_keys: 20).contents

  databases_sorted_by_date = database_objects.sort_by { |database_object| parse_timestamp(database_object.key) }.reverse

  last_uploaded_db = databases_sorted_by_date.first

  @r2.get_object({ bucket: 'spotify-data', key: last_uploaded_db.key }, target: last_uploaded_db.key)
end

# Parses the unix timestamp from the `spotify-data_123456789>.db` filename/key in S3
def parse_timestamp(object_key)
  timestamp_with_extension = object_key.split('_').last
  timestamp = timestamp_with_extension.split('.db').first
  Integer(timestamp)
end

main
