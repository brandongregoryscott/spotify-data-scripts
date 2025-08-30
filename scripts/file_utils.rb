# frozen_string_literal: true

def find_spotify_data_db
  Dir.glob('spotify-data*.db').first
end
