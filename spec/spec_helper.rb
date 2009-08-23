require 'pp'


require "#{File.dirname(__FILE__)}/../lib/simple_stats"
require "#{File.dirname(__FILE__)}/fixtures/video"
require "#{File.dirname(__FILE__)}/fixtures/user"

COUCH_DB = CouchRest.database!('http://127.0.0.1:5984/simplestats_test')
SimpleStats::Record.use_database COUCH_DB

def reset_test_db!
  COUCH_DB.recreate! rescue nil
  COUCH_DB
end

def mock_model(name)
  mock(name.to_sym).stub!(:id).and_return(rand(1000))
end

Spec::Runner.configure do |config|
  config.before(:all) { reset_test_db! }
  config.after(:all) do
    COUCH_DB.delete! rescue nil
  end
end