# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'aws-sdk-s3'
require 'date'
require_relative 'db_utils'
require_relative 'date_utils'
require_relative 'storage_utils'

@timestamp = rounded_current_timestamp

def main
  s3_key = db_name
  filename = s3_key
  object = Aws::S3::Object.new('spotify-data', s3_key, client: @r2)
  object.upload_file(filename)
end

main
