class User
  include SimpleStats::Extension

  attr_accessor :id
  simple_stats :as => :source
end