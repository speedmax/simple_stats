module SimpleStats
  module Extension
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      def simple_stats(options = {})
        Config.setup(options)
        
        class_eval do
          include Tracking

          if options[:as] == :source
            include Tracking::Source
          else
            include Tracking::Target
          end
        end
      end
      
      def delegate_stats(options = {})
        raise "Required to specify stats delegation target" unless options[:to]
        Config.setup
        
        if options[:prefix].nil?
          options[:prefix] = options[:to] 
        end
        
        class_eval do
          include Delegation
        end
        
        Delegation.attach(self, options)
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
