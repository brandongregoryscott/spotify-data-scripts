# spotify-data-scripts

Scripts for tracking Spotify artist changes over time.

## How it works

Every hour a cron job runs the [`Sync`](./scripts/sync.rb) script to sync a portion of artists from the `artist_ids` table from the Spotify API.

## Development

To run the sync script locally, you'll need [Ruby](https://www.ruby-lang.org/) installed. You'll also need a [Spotify Web API key](https://developer.spotify.com/documentation/web-api/tutorials/getting-started).

```sh
bundle install
CLIENT_IDS=abc123 CLIENT_SECRETS=xyz456 ruby scripts/sync.rb
```
