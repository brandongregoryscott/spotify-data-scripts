# spotify-data [![Sync](https://github.com/brandongregoryscott/spotify-data/actions/workflows/sync.yml/badge.svg)](https://github.com/brandongregoryscott/spotify-data/actions/workflows/sync.yml)

A repository for tracking Spotify artist changes over time.

## How it works

Every day the [`Sync`](./.github/workflows/sync.yml) workflow will run a Ruby script that hits the [Spotify API](https://developer.spotify.com/documentation/web-api/tutorials/getting-started) with the artist ids in the [`artists.json`](./input/artists.json) file. The data is saved by id in the [`output`](./output) directory, committed and pushed to the repository.

## Adding artists

Artist ids can be found by copying & pasting a link to the artist's profile from the Spotify web or desktop applications, which will be in the format: `https://open.spotify.com/artist/:artistId`. This id can then be added to the array in the [`artists.json`](./input/artists.json) file.

## Development

To run the sync script locally, you'll need [Ruby](https://www.ruby-lang.org/) installed. You'll also need a [Spotify Web API key](https://developer.spotify.com/documentation/web-api/tutorials/getting-started).

```sh
bundle install
CLIENT_IDS=abc123 CLIENT_SECRETS=xyz456 ruby scripts/sync.rb
```

## Expanding the git history

The git history for an artist can be expanded into a JSON file that contains an object for each snapshot of the artist's metadata. This file can be uploaded to a database or dropped into a charting library to visualize the changes over time.

To expand an artist's history, run the `expand_artist_history.rb` script with the id of the artist as a command-line argument:

```sh
ruby scripts/expand_artist_history.rb 6lcwlkAjBPSKnFBZjjZFJs
```

## Building a SQLite database

The git history for all artists can be iterated to build a SQLite database for embedding into your application, or using for local development with the [arthistory](https://github.com/brandongregoryscott/arthistory) app.

To build the SQLite database, run the `build_sqlite_database.rb` script. You can optionally provide `skip` and `take` command-line arguments to generate a smaller subset of data for testing.

```sh
# Generates a database for the entire git history
ruby scripts/build_sqlite_database.rb

# Only generate snapshots for the last 20 commits
ruby scripts/build_sqlite_database.rb --take 20

# Run with logging output
ruby scripts/build_sqlite_database.rb --verbose
```

A sample database can also be built via the [`Build SQLite Database Sample`](./.github/workflows/build-sqlite-database-sample.yml) workflow without having to download this repo and setup Ruby on your local machine. Instead, a GitHub Action will build the database and it will be uploaded to the GitHub Actions artifact storage. Be aware that even with the default settings (5 most recent commits), the run can take ~30 minutes before the database is ready to be downloaded.

### Reference

This repository was inspired by a project for tracking Spotify changes that I didn't end up finishing. A few years later, [_Git scraping: track changes over time by scraping to a Git repository_](https://simonwillison.net/2020/Oct/9/git-scraping/) by Simon Willison showed up on HackerNews and inspired me to implement the core of my idea.
