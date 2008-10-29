#!/usr/bin/env ruby

require 'rubygems'
require 'sqlite3'
require 'yaml'


# Generic query cache, to store keys and their values in an SQLite database
class SqliteCache
  attr_accessor :count_hits

  TABLE_NAME = 'query_cache'

  # Create a new SQLiteCache 
  def initialize( path )
    @db = SQLite3::Database.new( path )
    @count_hits = false

    # Wait up to 10 seconds to access locked database
    @db.busy_handler do |resource,retries|
      sleep 0.1
      retries<100
    end
    
    # Create the table, if it doesn't exist
    if @db.table_info(TABLE_NAME).empty?
      @db.execute( %Q{
        CREATE TABLE #{TABLE_NAME} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT,
          value TEXT,
          hits INTEGER DEFAULT 0,
          created_at INTEGER,
          updated_at INTEGER
        );
      } )
      @db.execute( %Q{ CREATE UNIQUE INDEX key_index ON #{TABLE_NAME} (key) } )
    end
  end
  
  # Delete everything in the cache
  def purge
    @db.execute( "DELETE FROM #{TABLE_NAME};" )
  end
  
  # Return the number of items in the cache
  def size
    @db.get_first_value( "SELECT COUNT(*) FROM #{TABLE_NAME};" ).to_i
  end

  # Fetch something from the cache, based on a key string
  def fetch( key )
    key = key.to_s.strip unless key.nil?
    raise "Invalid key" if key.nil? or key == ''

    id,value,hits = @db.get_first_row(
      "SELECT id,value,hits "+
      "FROM #{TABLE_NAME} "+
      "WHERE key=?",
      key.to_s.strip
    )

    # Return nil if there is cache MISS
    return nil if value.nil?
    
    # Increment the number of hits
    if @count_hits
      @db.execute(
        "UPDATE #{TABLE_NAME} SET hits=?, updated_at=? WHERE id=?",
        hits.to_i+1, Time.now.to_i, id
      )
    end

    # Otherwise if there is a HIT, parse the YAML into an object
    return YAML::load(value)
  end

  # Store a key and value in the cache
  def store( key, value )
    key = key.to_s.strip unless key.nil?
    raise "Invalid key" if key.nil? or key == ''
  
    @db.execute( %Q{
        INSERT INTO #{TABLE_NAME}
        (key,value,created_at)
        VALUES (?,?,?)
      },
      key,
      value.to_yaml,
      Time.now.to_i
    )
    
    return value
  end

  # Perform a block if key isn't already cached
  def do_cached( key, &block )
  
    # have a look in the cache
    value = fetch( key )

    # Cache HIT?
    return value unless value.nil?

    # Cache MISS : execute the block
    value = block.call( key )

    # Store value in the cache
    return store( key, value )
  end

end
