module SimpleStats
  module Delegation

    class << self
      def attach(base, options)
        prefix = ""
        prefix = "#{options[:prefix]}_" if options[:prefix] 
        target = options[:to].to_s
        
        delegate_methods.each do |method|
          # delegation method name
          delegate = if method =~ /_(year|month|day|hour|minute)$/
              'collect_stats_records_by_time'
            elsif methods = /_count$/
              'collect_stats_records_count'
            else
              'collect_stats_records'
          end

          base.class_eval <<-end_eval, __FILE__, __LINE__
          
            def #{prefix}#{method}(*args)
              #{delegate}(#{target}, :#{method}, *args)
            end
            
          end_eval
        end
      end

      def delegate_methods
        Config.supported_actions.inject([]) do |methods, action|
          
          methods << "#{action.pluralize}"
          methods << "#{action.pluralize}_count"

          %w(year month day hour minute).each do |type|
            methods << "#{action.pluralize}_by_#{type}"
          end
          
          methods
        end
      end
    end

    def collect_stats_records(objects, method, *args)
      objects.map{|o|o.send(method, *args) }.flatten!
    end
  
    def collect_stats_records_count(objects, method, *args)
      objects.map{|o|o.send(method, *args) }.sum
    end
  
    def collect_stats_records_by_time(objects, method, *args) 
      records = objects.map{|o| o.send(method, *args) }
  
      result = records.inject(Hash.new(0)) do |result, hash|
        result.merge!(hash) do |key, left, right|
          left + right
        end
      end
      result.to_a.sort_by(&:first)
    end

  end
end