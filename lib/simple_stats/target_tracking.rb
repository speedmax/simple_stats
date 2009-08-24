module SimpleStats
  module TargetTracking
    
    def self.included(base)
      # Memoization on query methods
      base.extend ActiveSupport::Memoizable

      Config.supported_actions.each do |action|
        attach_query_methods(base, action)

        attach_tracking_methods(base, action)
      end
    end

    # Generate tracking methods for a particular action
    # 
    # Example action : click 
    #  - track_click(attributes)
    #  - track_click_by(source, attributes)
    def self.attach_tracking_methods(klass, action)
      klass.class_eval <<-end_eval, __FILE__, __LINE__
      
        def #{Config.tracking_prefix}#{action}(attributes = {})
          attributes = {
            :action => '#{action}', 
            :target_id => self.id
          }.merge(attributes)
          
          Record.create!(attributes)
        end
        
        def #{Config.tracking_prefix}#{action}_by(source, attributes = {})
          self.#{Config.tracking_prefix}#{action}(
            {:source_id => source.id}.merge(attributes)
          )
        end
        
      end_eval
    end
        
    # Generate query methods for a particular action
    # 
    # Example action : click 
    #  - clicks
    #  - clicks_counts
    #  - clicks_timestamps
    def self.attach_query_methods(klass, action)
      method_name = "#{Config.query_prefix}#{action.pluralize}"

      klass.class_eval <<-end_eval, __FILE__, __LINE__
      
        def #{method_name} (date = nil, options = {})
          Record.by_action_and_target_id_and_accessed_at(
            conditions_for('#{action}', date, options)
          )
        end
        memoize :#{method_name}

        def #{method_name}_count (date = nil, options = {})
          Record.count(:by_action_and_target_id_and_accessed_at, 
            conditions_for('#{action}', date, options)
          )
        end
        memoize :#{method_name}_count

        def #{method_name}_timestamps (date = nil, options = {})
          options = {:raw => true, :reduce => false }.merge!(options)
          
          self.#{method_name}(date, options)['rows'].map do |row|
            row['key'].last
          end
        end
        memoize :#{method_name}_timestamps

      end_eval
    end
    
  end
end