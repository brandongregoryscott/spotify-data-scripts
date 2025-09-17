# frozen_string_literal: true

require 'date'

# Rounds time down to the nearest minute interval
# @see https://stackoverflow.com/a/449322
def round_time(time, minutes = 15)
  seconds = minutes * 60
  Time.at((time.to_f / seconds).floor * seconds).utc
end

def current_hour_index
  # - flag drops then padding
  hour = DateTime.now.strftime('%-H')
  Integer(hour)
end

def rounded_current_timestamp
  round_time(Time.now).to_i
end