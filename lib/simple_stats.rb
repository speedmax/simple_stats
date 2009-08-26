require 'rubygems'
require 'yaml'
require 'active_support'

begin
  require 'couchrest'
  raise if CouchRest.version < '0.3'
rescue Exception
  raise "
  You need install couchrest gem >= 0.3 
  Install latest couchrest gem using
    sudo gem install mattetti-couchrest --source http://gems.github.com
  " unless Kernel.const_defined?("CouchRest")
end

# Insert library to load path
$:.unshift File.dirname(__FILE__) unless
  $:.include?(File.dirname(__FILE__)) ||
  $:.include?(File.expand_path(File.dirname(__FILE__)))

# Simple Stats Service
module SimpleStats
  VERSION = '0.1' unless self.const_defined?("VERSION")

  autoload :Config,           'simple_stats/config'
  autoload :Record,           'simple_stats/record'
  autoload :Extension,        'simple_stats/extension'
  autoload :Tracking,         'simple_stats/tracking' 
  autoload :Delegation,       'simple_stats/delegation'
  autoload :SeqID,            'simple_stats/more/seq_id'
  
  require File.dirname(__FILE__) + '/simple_stats/tracking/target'
  require File.dirname(__FILE__) + '/simple_stats/tracking/source'
end
