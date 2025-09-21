# frozen_string_literal: true

require 'rspotify'
require 'rest-client'
require_relative 'date_utils'

def authenticate(index = nil, attempt = 1, max_retries = 25)
  client_ids = ENV['CLIENT_IDS'].split(',')
  client_secrets = ENV['CLIENT_SECRETS'].split(',')

  secret_index = !index.nil? ? index : current_hour_index % 8

  client_id = client_ids.at(secret_index) || client_ids.first
  client_secret = client_secrets.at(secret_index) || client_secrets.first

  RSpotify.authenticate(client_id, client_secret)
rescue RestClient::TooManyRequests, RestClient::ServiceUnavailable, RestClient::InternalServerError,
       RestClient::GatewayTimeout, RestClient::BadGateway, RestClient::Unauthorized
  max_sleep_seconds = Float(2**attempt)
  sleep rand(0.0..max_sleep_seconds)
  authenticate(index, attempt + 1) if attempt < max_retries
end
