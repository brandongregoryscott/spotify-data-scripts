# frozen_string_literal: true

require 'bundler/setup'
require 'sqlite3'
require 'pathname'
require 'git'
require 'date'
require 'json'
require 'optparse'

DEFAULT_LOG_SIZE = 5000
$verbose = false

def main
  options = parse_options
  $verbose = options[:verbose]

  git = Git.open(Pathname('.'))

  db = SQLite3::Database.new('output/_spotify-data.db')
  db.results_as_hash = true

  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS artist_snapshots (
      id TEXT,
      timestamp NUMERIC,
      followers NUMERIC,
      popularity NUMERIC,
      UNIQUE (id, timestamp)
    );
  SQL

  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS artists (
      id TEXT PRIMARY KEY,
      name TEXT
    );
  SQL

  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS git_history (
      sha TEXT PRIMARY KEY,
      timestamp NUMERIC
    );
  SQL

  save_artist_entries(db)

  stored_commits = db.execute('SELECT sha FROM git_history ORDER BY timestamp DESC;')

  starting_branch_or_sha = git.current_branch || git.revparse('HEAD')

  commits = commits_to_process(git, options)

  log("#{commits.count} commits in run: #{commits.first.sha}..#{commits.last.sha}")

  insertions = []

  commits.each_with_index do |commit, index|
    next if stored_commits.any? { |stored_commit| stored_commit['sha'] == commit.sha }

    log("(#{index + 1} / #{commits.count}) Processing #{commit.sha}")
    diff = git.diff(commit, "#{commit}~1")
    modified_files = diff.select { |file| modified_output_file?(file) }

    unless modified_files.empty?
      log("Generating snapshots for #{modified_files.length} files modified in commit #{commit.sha}")
    end

    git.checkout(commit)
    modified_files.each do |file|
      insertion_command = generate_insert_artist_snapshot_command(commit, file)
      insertions.push(insertion_command)

      insertions.clear if flush_insertion_commands_if_needed(db, insertions)
    end

    flush_insertion_commands(db, insertions)
    insertions.clear

    insert_git_history(db, commit)
  end

  checkout_starting_branch_or_commit(git, starting_branch_or_sha)
rescue SystemExit, Interrupt, SQLite3::ConstraintException, SQLite3::SQLException
  checkout_starting_branch_or_commit(git, starting_branch_or_sha)
end

def log(message)
  return unless $verbose

  puts("[#{DateTime.now.iso8601}] #{message}")
end

def checkout_starting_branch_or_commit(git, starting_branch_or_commit)
  git.checkout(starting_branch_or_commit)
end

def modified_output_file?(file)
  file.path.start_with?('output') && file.path.end_with?('.json') && file.type == 'modified'
end

def flush_insertion_commands_if_needed(db, insertions)
  return false unless insertions.length == 500

  flush_insertion_commands(db, insertions)

  true
end

def flush_insertion_commands(db, insertions)
  return if insertions.empty?

  db.transaction
  insertions.each do |insertion|
    db.execute(*insertion)
  end
  db.commit
end

def generate_insert_artist_snapshot_command(commit, file)
  timestamp = commit.date.to_i
  snapshot = JSON.parse(File.read(file.path))
  followers = snapshot['followers']['total']
  row = [snapshot['id'], timestamp, snapshot['popularity'], followers]
  ['INSERT INTO artist_snapshots (id, timestamp, popularity, followers) VALUES (?, ?, ?, ?);', row]
end

def generate_insert_artist_command(file_path)
  snapshot = JSON.parse(File.read(file_path))
  row = [snapshot['id'], snapshot['name']]
  [
    'INSERT OR IGNORE INTO artists (id, name) VALUES (?, ?);', row
  ]
end


def insert_git_history(db, commit)
  log("Inserting #{commit.sha} (#{commit.date}) into git_history table")
  db.execute('INSERT INTO git_history (sha, timestamp) VALUES (?, ?);', [commit.sha, commit.date.to_time.to_i])
rescue SQLite3::ConstraintException
  log("Skipping #{commit.sha} since it is already present in git_history table")
end

def parse_options
  options = {}

  OptionParser.new do |opts|
    opts.banner = 'Usage: ruby scripts/build_sqlite_database.rb [options]'

    opts.on('-v [flag]', '--verbose [flag]', TrueClass, 'Run with logging output') do |verbose|
      options[:verbose] = verbose.nil? ? true : verbose
    end

    opts.on('-s [number]', '--skip [number]', Integer, 'Number of commits to skip') do |skip|
      options[:skip] = skip
    end

    opts.on('-t [number]', '--take [number]', Integer, 'Number of commits to take') do |take|
      options[:take] = take
    end
  end.parse!

  options
end

def commits_to_process(git, options)
  if options[:skip] && options[:take]
    return git.log(DEFAULT_LOG_SIZE).path('output').skip(options[:skip]).take(options[:take])
  end

  return git.log(DEFAULT_LOG_SIZE).path('output').skip(options[:skip]) if options[:skip]

  return git.log(DEFAULT_LOG_SIZE).path('output').take(options[:take]) if options[:take]

  git.log(DEFAULT_LOG_SIZE).path('output')
end

def artist_file_paths
  Dir.entries('output').select { |f| File.file?(File.join('output', f)) && f.end_with?('.json') }.map { |f| File.join('output', f) }
end

def save_artist_entries(db)
  insertions = []
  artist_file_paths.each do |file_path|
    insertion_command = generate_insert_artist_command(file_path)
    insertions.push(insertion_command)
    insertions.clear if flush_insertion_commands_if_needed(db, insertions)
  end

  flush_insertion_commands(db, insertions)
end

main
