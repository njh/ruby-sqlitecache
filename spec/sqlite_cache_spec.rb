$:.unshift(File.dirname(__FILE__))

ROOT_DIR = File.join(File.dirname(__FILE__),'..')

require 'spec_helper'
require 'sqlite_cache'

describe SqliteCache do
  before(:each) do
    @cache_path = File.join(ROOT_DIR,'tmp','sqlite_cache_test') + '.db'
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
      @qc.store("hello", "value")
      @qc.size.should == @size+1
    end
    
    it "should return what was stored, when the value is a string" do
      @qc.store("hello", "string key")
      @qc.fetch("hello").should == "string key"
    end
    
    it "should return what was stored, when value is a hash" do
      data = { 1 => 'A', 2 => 'B', 3 => 'C', 4 => 'D'}
      @qc.store("hash value", data)
      @qc.fetch("hash value").keys.should eql(data.keys)
      @qc.fetch("hash value").values.should eql(data.values)
    end
    
    it "should return what was stored, when value is an array of arrays" do
      data = [ "A", "B", "C", [1,2,3,4] ]
      @qc.store("array of arrays", data)
      @qc.fetch("array of arrays").should eql(data)
    end
    
    it "should stringify the key and so should return the same for '1' and 1" do
      @qc.store(1, "integer key")
      @qc.fetch("1").should == "integer key"
    end
    
    it "should remove whitespace from the key" do
      @qc.store("whitespace   ", "whitespace value")
      @qc.fetch("   whitespace").should == "whitespace value"
    end
    
    it "should raise an exception if they key is nil when storing a value" do
      lambda { @qc.store(nil, "value") }.should raise_error(RuntimeError, "Invalid key")
    end
    
    it "should raise an exception if they key is nil when fetching a value" do
      lambda { @qc.fetch(nil) }.should raise_error(RuntimeError, "Invalid key")
    end


  end

  describe "when performing a cached key" do
    before(:each) do
      @size = @qc.size
      @value = @qc.do_cached(10) { |q| q + 5 }
    end
  
    it "should return the correct value for the key" do
      @value.should == 15
    end
  
    it "should add something to the cache" do
      @qc.size.should == @size+1
    end
  
    it "should return the same result if the key is performed again" do
      @qc.do_cached(10) { 999 }.should == 15
    end

    it "should not add other entry if the same key is performed again" do
      @value = @qc.do_cached(10) { |q| q + 5 }
      @qc.size.should == @size+1
    end
  end
  
  
  describe "when purging the cache" do
    it "should be empty" do
      @qc.store("hello", "value")
      @qc.size.should == 1
      @qc.purge
      @qc.size.should == 0
    end
  end
  
end
