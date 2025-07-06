# frozen_string_literal: true

require 'bundler/setup'
require 'git'
require 'date'
require 'pathname'
require 'logger'

MAX_RETRIES = 5

def main
  logger = Logger.new($stdout)
  git = Git.open(Pathname('.'), log: logger)

  branch_name = git.current_branch

  git.add('output')
  exit(0) if git.status.none? { |file| modified_file?(file) }
  git.commit(DateTime.now.iso8601)

  if current_hour == 23
    merge_and_delete_daily_branch(git, branch_name)
    return
  end

  git.push('origin', branch_name)
end

def merge_and_delete_daily_branch(git, branch_name)
  git.checkout('main')
  system("git merge --squash  #{branch_name}")
  git.commit(branch_name)
  delete_remote_branch(git, branch_name)
  push_main_branch(git)
end

def delete_remote_branch(git, branch_name, attempt = 1)
  git.push('origin', branch_name, delete: true)
rescue Git::FailedError
  max_sleep_seconds = Float(2**attempt)
  sleep rand(0..max_sleep_seconds)
  delete_remote_branch(git, branch_name, attempt + 1) if attempt < MAX_RETRIES
end

def push_main_branch(git, attempt = 1)
  git.push('origin', 'main')
rescue Git::FailedError
  max_sleep_seconds = Float(2**attempt)
  sleep rand(0..max_sleep_seconds)
  push_main_branch(git, attempt + 1) if attempt < MAX_RETRIES
end

def current_hour
  # - flag drops then padding
  hour = DateTime.now.strftime('%-H')
  Integer(hour)
end

def modified_file?(file)
  file.path.start_with?('output') && (file.type == 'M' || file.type == 'A')
end

main
