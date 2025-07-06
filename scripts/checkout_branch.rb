# frozen_string_literal: true

require 'bundler/setup'
require 'git'
require 'date'
require 'pathname'
require 'logger'

def main
  logger = Logger.new($stdout)
  git = Git.open(Pathname('.'), log: logger)

  configure_git_user(git)
  checkout_branch(git)
end

def configure_git_user(git)
  git.config('user.name', 'github-actions[bot]')
  git.config('user.email', '41898282+github-actions[bot]@users.noreply.github.com')
  git.config('pull.rebase', 'false')
end

def checkout_branch(git)
  git.fetch('origin', unshallow: true)

  branch_name = current_date
  is_new_branch = !git.is_branch?(branch_name)

  git.checkout(branch_name, new_branch: is_new_branch)

  git.pull('origin', branch_name) unless is_new_branch
  git.pull('origin', 'main')
end

def current_date
  DateTime.now.strftime('%Y-%m-%d')
end

main
