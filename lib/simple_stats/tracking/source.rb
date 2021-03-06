module SimpleStats
  module Tracking
    module Source

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
          tracking+ '_on'     => 'tracking_on_target',

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

      ##
      # Tracking methods
      def tracking_on_target(action, target, attrs = {})
        Record.create!(
          { :action => action,
            :target_id => target.id, 
            :target_type => target.class.to_s,
            :source_id => self.id,
            :source_type => self.class.to_s
          }.merge(attrs)
        )
      end

      ##
      # Query and reporting methods

      # Return stats reocrds (ie: source.clicks)
      def stats_records(*args)
        Record.by_action_and_source_id_and_accessed_at conditions_for(*args)
      end

      # Return stats reocrds counts (ie: source.clicks_count)
      def stats_records_count(action, date = nil, options ={})
        results = Summery.by_timestamp_and_type_and_trackable_action(
          aggregated_conditions_for('source', action, date, {:reduce => true, :raw => true}.merge(options))
        )["rows"]
        
        if results.first && results.first['value']
          return results.first['value']
        end
        
        0
      end

      # Return stats reocrds count by minute (ie: source.clicks_by_minute)
      def stats_records_by_minute(*args)
        if Config.query_method == :aggregated
          records = fetch_aggregated_records(*args)
        else
          records = fetch_raw_records(*args)
        end
        slice_stats(records, 0, 16)
      end

      # Return stats reocrds count by hour (ie: source.clicks_by_hour)
      def stats_records_by_hour(*args)
        records = stats_records_by_minute(*args)
        slice_stats(records, 0, 13)
      end

      # Return stats reocrds count by day (ie: source.clicks_by_day)
      def stats_records_by_day(*args)
        records = stats_records_by_hour(*args)
        slice_stats(records, 0, 10)
      end

      # Return stats reocrds count by month (ie: source.clicks_by_month)
      def stats_records_by_month(*args)
        records = stats_records_by_hour(*args)
        slice_stats(records, 0, 7)
      end

      # Return stats reocrds count by year (ie: source.clicks_by_year)
      def stats_records_by_year(*args)
        records = stats_records_by_hour(*args)
        slice_stats(records, 0, 4)
      end
    
    private
      def fetch_raw_records(action, date = nil, options = {})
        records = Record.by_action_and_source_id_and_accessed_at(
          conditions_for(action, date, {:raw => true, :reduce => false }.merge(options))
        )['rows']
        records.map!{|row| [ row['key'].last, 1] }
      end

      def fetch_aggregated_records(action, date = nil, options = {})
        conditions = aggregated_conditions_for(
          'source', action, date, {:raw => true, :reduce => false}.merge(options)
        )
        records = Summery.by_timestamp_and_type_and_trackable_action(conditions)["rows"]
        
        records.map! do |row|
          time = Time.at(row["key"].last / 1000).utc.to_json[1..-1]
          [time, row["value"]]
        end
      end
    end
  end
end