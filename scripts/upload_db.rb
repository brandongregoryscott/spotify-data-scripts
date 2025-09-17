# frozen_string_literal: true

require 'bundler/setup'
require 'aws-sdk-s3'
require 'date'
require_relative 'db_utils'
require_relative 'date_utils'
require_relative 'storage_utils'

@timestamp = rounded_current_timestamp

def main
  object = Aws::S3::Object.new('spotify-data', db_name, client: @r2)
  object.upload_file(db_name)
end

main
