# frozen_string_literal: true

def create_artist_ids_table(db)
  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS artist_ids (
      id TEXT PRIMARY KEY
    );
  SQL
end

def create_artist_snapshots_table(db)
  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS artist_snapshots (
      id TEXT,
      timestamp NUMERIC,
      followers NUMERIC,
      popularity NUMERIC,
      UNIQUE (id, timestamp)
    );
  SQL
end

def bulk_insert(db, items, generate_insert_commands, chunk_size = 50, flush_after = 500)
  insertions = []
  items.each_slice(chunk_size) do |items_chunk|
    insertions.concat(generate_insert_commands.call(items_chunk))
    insertions.clear if flush_insertion_commands_if_needed(db, insertions, flush_after)
  end

  flush_insertion_commands(db, insertions)
  insertions.clear
end

def flush_insertion_commands_if_needed(db, insertions, flush_after)
  return false unless insertions.length == flush_after

  flush_insertion_commands(db, insertions)
end

def flush_insertion_commands(db, insertions)
  return false if insertions.empty?

  db.transaction
  insertions.each do |insertion|
    db.execute(*insertion)
  end
  db.commit

  true
end
