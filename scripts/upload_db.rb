# frozen_string_literal: true

require 'bundler/setup'
require 'aws-sdk-s3'
require 'date'
require_relative 'file_utils'
require_relative 'date_utils'

S3_ENDPOINT = ENV['AWS_S3_ENDPOINT']
ACCESS_KEY_ID = ENV['AWS_ACCESS_KEY_ID']
SECRET_ACCESS_KEY = ENV['AWS_SECRET_ACCESS_KEY']

@timestamp = round_time(Time.now).to_i
@r2 = Aws::S3::Client.new(
  access_key_id: ACCESS_KEY_ID,
  secret_access_key: SECRET_ACCESS_KEY,
  endpoint: S3_ENDPOINT,
  region: 'auto'
)

def main
  db_name = find_spotify_data_db

  object = Aws::S3::Object.new('spotify-data', "spotify-data_#{@timestamp}.db", client: @r2)
  object.upload_file(db_name)
end

main
