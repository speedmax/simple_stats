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
        :startkey => [action, self.id, Time.parse(from.beginning_of_day.to_s)],
        :endkey => [action, self.id, Time.parse(to.end_of_day.to_s)]
      }.merge(options)
    end
  end
end