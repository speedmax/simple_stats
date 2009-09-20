require 'pp'
require "#{File.dirname(__FILE__)}/../lib/simple_stats"
require "#{File.dirname(__FILE__)}/fixtures/video"
require "#{File.dirname(__FILE__)}/fixtures/user"
require "#{File.dirname(__FILE__)}/fixtures/item"


raise "Please install a new version rspec" if Spec::VERSION::STRING < "1.2.8"

TEST_COUCHDB = CouchRest.database!('http://127.0.0.1:5984/simplestats_test') unless defined?(TEST_COUCHDB)
SimpleStats::Record.use_database TEST_COUCHDB
SimpleStats::Summery.use_database TEST_COUCHDB

def reset_test_db!
  TEST_COUCHDB.recreate! rescue nil
  TEST_COUCHDB
end

def mock_model(name)
  record = name.classify.constantize.new
  record.id = rand(1000) + Time.new.usec
  record
end

Spec::Runner.configure do |config|
  config.before(:all) do
    reset_test_db!
  end
  
  config.after(:all) do
    # TEST_COUCHDB.delete! rescue nil
  end
end