module SimpleStats
  module Tracking

  private
    def slice_stats(records, from, to)
      records.inject(Hash.new(0)) do |hash, (key, value)|
        hash[key[from, to]] += value

        hash
      end
    end
  
    # Build condition for search
    def conditions_for(action, from = nil, options = {})
      from, to = normalize_daterange(from)
      
      conditions = {
        :startkey => [action, self.id, self.class.to_s, Time.at(from.to_i)],
        :endkey => [action, self.id, self.class.to_s, Time.at(to.to_i)]
      }.merge(options)
    end
    
    def aggregated_conditions_for(type, action, from = nil, options = {})
      from, to = normalize_daterange(from)
      conditions = { 
        :startkey => [type, self.class.to_s, self.id, action, from.utc.to_js_timestamp],
        :endkey => [type, self.class.to_s, self.id, action, to.utc.to_js_timestamp]
      }.merge(options)
    end
    
    def normalize_daterange(from = nil)
      case from
      when Range
        from, to = from.first, from.last
      when Date, Time, nil
        from = Time.now unless from
      
        from = from.beginning_of_day
        to = from.end_of_day
      end
      
      [from, to]
    end
  end
end