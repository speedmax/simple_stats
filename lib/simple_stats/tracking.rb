module SimpleStats
  module Tracking

    # Build condition for search
    def conditions_for(action, from = nil, options = {})
     from = Time.now unless from

     if from.is_a? Range
       from, to = from.first, from.last
     else
       to = from
     end
     conditions = {
       :startkey => [action, self.id, Time.parse(from.beginning_of_day.to_s)],
       :endkey => [action, self.id, Time.parse(to.end_of_day.to_s)]
     }.merge(options)
    end
  end
end