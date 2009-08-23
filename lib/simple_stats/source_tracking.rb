module SimpleStats
  module SourceTracking
    
    def self.included(base)
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

        def #{Config.tracking_prefix}#{action}(attributes)
          attributes = {:source_id => self.id}.merge!(attributes)
          Record.new(attributes).save
        end
        
        def #{Config.tracking_prefix}#{action}_on(source, attributes)
          self.#{Config.tracking_prefix}#{action}(attributes.merge(:source => source.id))
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
      klass.class_eval <<-end_eval, __FILE__, __LINE__
      
        def #{Config.query_prefix}#{action.pluralize} (date =nil, options = {})
          Record.by_action_and_source_id_and_accessed_at(
            conditions_for('#{action}', date, options)
          )
        end

        def #{Config.query_prefix}#{action.pluralize}_count (date =nil, options = {})
          Record.count(:by_action_and_source_id_and_accessed_at, 
            conditions_for('#{action}', date, options)
          )
        end

        def #{Config.query_prefix}#{action.pluralize}_timestamps (date =nil, options = {})
          self.#{action.pluralize}(date, options)['rows'].map do |row|
            row['key'][1]
          end
        end

      end_eval
    end

  end
end