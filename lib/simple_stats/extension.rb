module SimpleStats
  module Extension

    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module ClassMethods
      def simple_stats(options = {})
        Config.setup(options)
 
        if options[:as] == :source
          tracking_method = SourceTracking
        else
          tracking_method = TargetTracking
        end
        
        class_eval do
          include tracking_method
        end
      end
    end

    module InstanceMethods

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
end

if defined?(::ActiveRecord)
  module ::ActiveRecord
    class Base
      include SimpleStats::Extension
    end
  end
end
