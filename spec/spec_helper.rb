require 'pp'
require "#{File.dirname(__FILE__)}/../lib/simple_stats"
require "#{File.dirname(__FILE__)}/fixtures/video"
require "#{File.dirname(__FILE__)}/fixtures/user"
require "#{File.dirname(__FILE__)}/fixtures/item"


COUCH_DB = CouchRest.database!('http://127.0.0.1:5984/simplestats_test')
SimpleStats::Record.use_database COUCH_DB

def reset_test_db!
  COUCH_DB.recreate! rescue nil
  COUCH_DB
end

def mock_model(name)
  record = name.classify.constantize.new
  record.stub!(:id).and_return(rand(1000))
  record
end

Spec::Runner.configure do |config|
  config.before(:all) do
    reset_test_db!
  end
  config.after(:all) do
    # COUCH_DB.delete! rescue nil
  end
end