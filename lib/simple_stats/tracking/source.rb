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
          {:action => action, :target_id => target.id, :source_id => self.id }.merge(attrs)
        )
      end

      ##
      # Query and reporting methods

      # Return stats reocrds (ie: source.clicks)
      def stats_records(*args)
        Record.by_action_and_source_id_and_accessed_at conditions_for(*args)
      end

      # Return stats reocrds counts (ie: source.clicks_count)
      def stats_records_count(*args)
        Record.count(:by_action_and_source_id_and_accessed_at,
          conditions_for(*args)
        )
      end

      # Return stats reocrds count by minute (ie: source.clicks_by_minute)
      def stats_records_by_minute(action, date = nil, options = {})
        records = Record.by_action_and_source_id_and_accessed_at(
          conditions_for(action, date, {:raw => true, :reduce => false }.merge(options))
        )['rows']

        records.inject(Hash.new(0)) do |hash, row|
          hash[row['key'].last[0, 16]] += 1
          hash
        end
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
      def slice_stats(records, from, to)
        records.inject(Hash.new(0)) do |hash, (key, value)|
          hash[key[from, to]] += value

          hash
        end
      end
    end
  end
end