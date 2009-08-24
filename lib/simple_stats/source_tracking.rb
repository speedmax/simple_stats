module SimpleStats
  module SourceTracking
    
    def self.included(base)
      # Memoization on query methods
      base.extend ActiveSupport::Memoizable

      Config.supported_actions.each do |action|
        attach_tracking_methods(base, action)
        attach_query_methods(base, action)
      end
    end
    
    # Generate tracking methods for a particular action
    # 
    # Example action : click 
    #  - track_click(attributes)
    #  - track_click_on(target, attributes)
    def self.attach_tracking_methods(klass, action)
      klass.class_eval <<-end_eval, __FILE__, __LINE__

        def #{Config.tracking_prefix}#{action}_on(target, attributes = {})
          attributes = {
            :action => '#{action}', 
            :source_id => self.id,
            :target_id => target.id
          }.merge(attributes)
          Record.create!(attributes)
        end

      end_eval
    end

    # Generate reporting methods for a particular action
    # 
    # Example action : click 
    #  - clicks
    #  - clicks_counts
    #  - clicks_timestamps
    def self.attach_query_methods(klass, action)
      method_name = "#{Config.query_prefix}#{action.pluralize}"

      klass.class_eval <<-end_eval, __FILE__, __LINE__
      
        def #{method_name} (date =nil, options = {})
          Record.by_action_and_source_id_and_accessed_at(
            conditions_for('#{action}', date, options)
          )
        end
        

        def #{method_name}_count (date =nil, options = {})
          Record.count(:by_action_and_source_id_and_accessed_at, 
            conditions_for('#{action}', date, options)
          )
        end

        def #{method_name}_timestamps (date =nil, options = {})
          options = {:raw => true, :reduce => false }.merge!(options)
          
          self.#{method_name}(date, options)['rows'].map do |row|
            row['key'].last
          end
        end

        def #{method_name}_by_hour(date = nil, options = {})
          records = SimpleStats::Record.by_action_and_source_id_and_accessed_at(
            conditions_for('#{action}', date, {:raw => true, :reduce => false }.merge(options))
          )['rows']

          records.map! do |row|
            row['key'].last[0, 13]
          end

          records.inject(Hash.new(0)) do |hash, value|
            hash[value] += 1
            hash
          end
        end

        def #{method_name}_by_day(date = nil, options = {}) 
          #{method_name}_by_hour(date, options).inject(Hash.new(0)) do |hash, (key, value)|
            hash[key[0, 10]] += value

            hash
          end
        end

        def #{method_name}_by_month(date = nil, options = {})
          #{method_name}_by_hour(date, options).inject(Hash.new(0)) do |hash, (key, value)|
            hash[key[0, 7]] += value

            hash
          end
        end

      end_eval
    end

  end
end