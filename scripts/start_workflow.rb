# frozen_string_literal: true

require 'bundler/setup'
require 'octokit'

def main
  token = ENV['GITHUB_ACCESS_TOKEN']
  client = Octokit::Client.new(access_token: token)
  start_workflow(client)
end

def start_workflow(client, attempt = 1)
  dispatched = client.workflow_dispatch('brandongregoryscott/spotify-data', '92677804', 'main')

  return if dispatched

  max_sleep_seconds = Float(2**attempt)
  sleep rand(0.0..max_sleep_seconds)
  start_workflow(client, attempt + 1)
end

main
