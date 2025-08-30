# frozen_string_literal: true

require 'bundler/setup'
require 'aws-sdk-s3'
require 'date'

S3_ENDPOINT = ENV['AWS_S3_ENDPOINT']
ACCESS_KEY_ID = ENV['AWS_ACCESS_KEY_ID']
SECRET_ACCESS_KEY = ENV['AWS_SECRET_ACCESS_KEY']

@r2 = Aws::S3::Client.new(
  access_key_id: ACCESS_KEY_ID,
  secret_access_key: SECRET_ACCESS_KEY,
  endpoint: S3_ENDPOINT,
  region: 'auto'
)

def main

  object = Aws::S3::Object.new('spotify-data', "spotify-data_#{Time.now.to_i}.db", client: @r2)
  object.upload_file('spotify-data_1751481126928.db')
end

main
