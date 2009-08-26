class User
  include SimpleStats::Extension

  attr_accessor :id, :items
  
  # Track this model
  simple_stats :as => :source
  
  # delegate stats to item
  delegate_stats :to => :items
end