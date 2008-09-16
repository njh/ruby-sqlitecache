#require File.dirname(__FILE__) + '/../spec_helper'

describe SqliteCache do
  before(:each) do
    @cache_path = File.join(RAILS_ROOT,'tmp','query_cache_test') + '.db'
    File.delete( @cache_path ) if File.exists?( @cache_path )
    @qc = SqliteCache.new( @cache_path )
  end
  
  describe "when storing and retrieve something from the cache" do
    before(:each) do
      @size = @qc.size
    end
    
    it "should create an SQLite database file" do
      File.exists?( @cache_path ).should be_true
    end
    
    it "should increment the size of the cache" do
      @qc.store("hello", "response")
      @qc.size.should == @size+1
    end
    
    it "should return what was stored" do
      @qc.store("hello", "response")
      @qc.fetch("hello").should == "response"
    end
    
    it "should return what was stored, when key is a hash" do
      @qc.store({:hello => :world}, "response")
      @qc.fetch({:hello => :world}).should == "response"
    end
    
    it "should return what was stored, when response is a hash" do
      data = { 1 => 'A', 2 => 'B', 3 => 'C', 4 => 'D'}
      @qc.store("query string", data)
      @qc.fetch("query string").keys.should eql(data.keys)
      @qc.fetch("query string").values.should eql(data.values)
    end
    
    it "should return what was stored, when response is an array of arrays" do
      data = [ "A", "B", "C", [1,2,3,4] ]
      @qc.store("query string", data)
      @qc.fetch("query string").should eql(data)
    end
  end

  describe "when performing a cached query" do
    before(:each) do
      @size = @qc.size
      @response = @qc.do_cached(10) { |q| q + 5 }
    end
  
    it "should return the correct response the the query" do
      @response.should == 15
    end
  
    it "should add something to the cache" do
      @qc.size.should == @size+1
    end
  
    it "should return the same result if the query is performed again" do
      @qc.do_cached(10) { 999 }.should == 15
    end
    
  
    it "should not add other entry if the same query is performed again" do
      @response = @qc.do_cached(10) { |q| q + 5 }
      @qc.size.should == @size+1
    end

  end
  
  
  describe "when purging the cache" do
    it "should be empty" do
      @qc.store("hello", "response")
      @qc.size.should == 1
      @qc.purge
      @qc.size.should == 0
    end
  end
  
end
