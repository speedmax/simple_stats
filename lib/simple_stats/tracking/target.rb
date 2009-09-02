module SimpleStats
  module Tracking
    module Target
      
      def self.included(base)

        # Attach all tracking and query methods
        Config.supported_actions.each do |action|
          method_mapping_for(action).each do |method, delegate|
            base.class_eval <<-end_eval, __FILE__, __LINE__
              def #{method}(*args)
                #{delegate}('#{action}', *args)
              end
            end_eval
          end
        end
        
        # Memoization
        if Config.memorize && !base.is_a?(ActiveSupport::Memoizable)
          base.extend ActiveSupport::Memoizable
          base.class_eval do
            memoize :stats_records_by_minute, :stats_records_count
          end
        end
      end

      def self.method_mapping_for(action)
        tracking = Config.tracking_prefix + action
        query = Config.query_prefix + action.pluralize
        {
          # tracking methods
          tracking            => 'tracking',
          tracking+ '_by'     => 'tracking_by_source',
          
          # query methods
          query                 => 'stats_records',
          query + "_count"      => 'stats_records_count',
          query + "_by_minute"  => 'stats_records_by_minute',
          query + "_by_hour"    => 'stats_records_by_hour',
          query + "_by_day"     => 'stats_records_by_day',
          query + "_by_month"   => 'stats_records_by_month',
          query + "_by_year"    => 'stats_records_by_year'
        }
      end
      
      # Tracking methods
      def tracking(action, attrs = {})
        Record.create!(
          {:action => action, :target_id => self.id, :target_type => self.class.to_s }.merge(attrs)
        )
      end
      
      def tracking_by_source(action, source, attrs = {})
        Record.create!(
          {
            :action => action,
            :target_id => self.id,
            :target_type => self.class.to_s,
            :source_id => source.id,
            :source_type => source.class.to_s
          }.merge(attrs)
        )
      end

      # Query and reporting methods
      def stats_records(*args)
        Record.by_action_and_target_id_and_accessed_at conditions_for(*args)
      end
      
      def stats_records_count(*args)
        Record.count(:by_action_and_target_id_and_accessed_at, conditions_for(*args))
      end

      
      def stats_records_by_minute(action, date = nil, options = {})
        records = Record.by_action_and_target_id_and_accessed_at(
          conditions_for(action, date, {:raw => true, :reduce => false }.merge(options))
        )['rows']

        records.inject(Hash.new(0)) do |hash, row|
          hash[row['key'].last[0, 16]] += 1
          hash
        end
      end

      def stats_records_by_hour(*args)
        records = stats_records_by_minute(*args)
        slice_stats(records, 0, 13)
      end
      
      def stats_records_by_day(*args)
        records = stats_records_by_hour(*args)
        slice_stats(records, 0, 10)
      end
      
      def stats_records_by_month(*args)
        records = stats_records_by_hour(*args)
        slice_stats(records, 0, 7)
      end
      
      def stats_records_by_year(*args)
        records = stats_records_by_hour(*args)
        slice_stats(records, 0, 4)
      end
    
    private
      def slice_stats(records, from, to)
        records.inject(Hash.new(0)) do |hash, (key, value)|
          hash[key[from, to]] += value

          hash
        end
      end
    end
  end
end