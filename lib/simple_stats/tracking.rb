module SimpleStats
  module Tracking

    # Build condition for search
    def conditions_for(action, from = nil, options = {})
      case from
      when Range
        from, to = from.first, from.last
      when Date, Time
        to = from
      else
        to = from = Time.now
      end

      conditions = {
        :startkey => [action, self.id, self.class.to_s, Time.at(from.beginning_of_day)],
        :endkey => [action, self.id, self.class.to_s, Time.at(to.end_of_day)]
      }.merge(options)
    end
  end
end