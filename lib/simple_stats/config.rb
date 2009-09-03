module SimpleStats
  class Config
    class << self
      def setup(options = {})
        @options = default_options.merge(options)
      end
      
      def default_options
        {
          :supported_actions  => ['click', 'impression'],
          :tracking_prefix    => 'track_',
          :query_prefix       => '',
          :memorize           => false,
          :record_class       => SimpleStats::Record,
          :summery_class      => SimpleStats::Summery,
          :summery_padding    => 20.seconds,
          :summery_interval   => 10.minutes,
          :query_method       => :raw
        }
      end
      
      def method_missing(method, *args)
        if default_options[method] && @options[method]
          @options[method]
        elsif method =~ /=$/
          method = method[0...-1]
          @options[method] = args.shift
        end
      end
    end
  end
end