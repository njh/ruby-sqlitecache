#!/usr/bin/env ruby

require 'rubygems'
require 'sqlite3'
require 'yaml'


# Generic query cache, to store queries and their responses in an SQLite database
class SqliteCache

  # Create a new SQLiteCache 
  def initialize( path )
    @db = SQLite3::Database.new( path )
    @db.busy_timeout(500)
    @db.execute( %q[
      CREATE TABLE IF NOT EXISTS query_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT,
        response TEXT,
        hits INTEGER DEFAULT 0,
        created_at INTEGER
      );
    ] )
  end
  
  # Delete everything in the cache
  def purge
    @db.execute( "DELETE FROM query_cache;" )
  end
  
  # Return the number of items in the cache
  def size
    @db.get_first_value( "SELECT COUNT(*) FROM query_cache;" ).to_i
  end

  # Fetch something from the cache, based on a query object
  def fetch( query )
    id,response,hits = @db.get_first_row(
      "SELECT id,response,hits "+
      "FROM query_cache "+
      "WHERE query=?", 
      query.to_yaml( :SortKeys => true )
    )

    # Return nil if there is cache MISS
    return nil if response.nil?
    
    # Increment the number of hits
    @db.execute("UPDATE query_cache SET hits=? WHERE id=?", hits.to_i+1, id)

    # Otherwise if there is a HIT, parse the YAML into an object
    return YAML::load(response)
  end

  # Store a query and response in the cache
  def store( query, response )
    @db.execute(
      %q{
        INSERT INTO query_cache
        (query,response,created_at)
        VALUES (?,?,?)
      },
      query.to_yaml( :SortKeys => true ),
      response.to_yaml,
      Time.now.to_i
    )
    
    return response
  end

  # Perform a block if query isn't already cached
  def do_cached( query, &block )
  
    # have a look in the cache
    response = fetch(query)

    # Cache HIT?
    return response unless response.nil?

    # Cache MISS : execute the block
    response = block.call(query)

    # Store response in the cache
    return store( query, response )
  end

end
