class Item
  include SimpleStats::Extension

  attr_accessor :id
  simple_stats
end