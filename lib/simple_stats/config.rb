module SimpleStats
  class Config
    class << self
      def setup(options = {})
        @options = default_options.merge(options)
      end
      
      def default_options
        {
          :supported_actions => ['click', 'impressions'],
          :tracking_prefix => 'track_',
          :query_prefix => '',
          :record_class => SimpleStats::Record
        }
      end
      
      def method_missing(config)
        if default_options[config] && @options[config]
          @options[config]
        end
      end
    end
  end
end