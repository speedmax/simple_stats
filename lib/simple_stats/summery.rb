module SimpleStats
  
##
#  Summerized and aggregated stats and analytic data for queries
#  It aggregated stats record for predefined interval of time and it
#  will create a aggregated sumemry record for every 10 minutes
#
  class Summery < CouchRest::ExtendedDocument
    include ::SimpleStats::Tracking
    unique_id :generate_uuid

    # Target or Source
    property :name
    property :type
    property :trackable_type
    property :trackable_id
    
    # Click/impression
    property :count

    view_by :type, :trackable_type, :trackable_id, :_id
    view_by :timestamp_and_type_and_trackable_action,
      :map => 
        "function(doc) {
          if ((doc['couchrest-type'] == 'SimpleStats::Summery') && doc.trackable_id && doc.trackable_type && doc.count) {
            var unbase16 = function(num){
              var base='0123456789abcdef', ret=0;
              for(var x=1;num.length>0;x*=base.length){
                ret += base.indexOf(num.charAt(num.length-1)) * x
                num = num.substr(0,num.length-1);
              }
              return ret;
            }
            var timestamp = unbase16(doc._id.substring(0, 12))

            for (action in doc.count) {
              emit([timestamp, doc.type, doc.trackable_type, doc.trackable_id, action], doc.count[action])
            }
          }
        }",
      :reduce => "function(k, v) {return sum(v);}"
        
    class << self
      def create_or_find(attributes = {})
        {
          :count        => {},
          :type         => summery_type,
          :trackable_type => doc[trackable_type],
          :trackable_id   => doc[trackable_id],
        }
      end
      
      # Build stats summeries
      # 
      # Default report interval is 10 minutes
      # Report duration will add 20 percent of time as padding
      # start_time =  Current time - (report interval x 20%)
      # end_time = start_time - interval (ie: 10.minutes)
      def build(interval = 10.minutes, from = Time.now)
        padding = Config.summery_padding
        limit = Time.now.every(interval).utc
        results = []        

        unless last = self.last
          accessed_at = Time.parse(Config.record_class.first.accessed_at).utc
          report_start = accessed_at.every(interval) - interval
        else
          report_start = Time.parse(last[:to]).utc + 1.second
        end

        cached_records = Config.record_class.by_accessed_at(
          :startkey     => report_start,
          :endkey       => limit,
          :raw          => true,
          :include_docs => true
        )["rows"]

        start_time = report_start

        ((report_start - limit) / interval).abs.to_i.times do
          report_range = start_time .. (start_time + interval - 1.second)
          
          records = cached_records.select do |record| 
            time = record["id"][0,12].to_i(16)/1000.to_f
            time >= report_range.first.to_i and time <= report_range.last.to_i
          end
          
          results += self.build_for(:target, report_range, records)
          results += self.build_for(:source, report_range, records)

          start_time += interval
        end

        results
      end

      def expired?(interval = 10.minutes)
        padding = Config.summery_padding
        expired = Time.now >= Time.now.every(interval) + padding
                
        if previous = self.last
          diff = Time.now.every(interval) - previous.created_at
          return expired && (diff >= interval)
        end
        
        !previous || expired 
      end

      def build_for(summery_type, report_range, records = false)

        # fetch all records
        records = Config.record_class.by_accessed_at(
          :startkey     => report_range.first,
          :endkey       => report_range.last,
          :raw          => true,
          :include_docs => true
        )["rows"] unless records

        trackable_type = "#{summery_type}_type"
        trackable_id = "#{summery_type}_id"

        # build all summery records in a data hash
        data = {}
        records.each do |record|
          doc = record["doc"]
          action = doc["action"]
          
          # skip if record doesn't contain data for current reporting trackable
          next unless doc[trackable_type] && doc[trackable_id]

          data[doc[trackable_id]] ||= {
            :count        => {},
            :type         => summery_type,
            :from         => report_range.first,
            :to           => report_range.last,
            :trackable_type => doc[trackable_type],
            :trackable_id   => doc[trackable_id],
          }
          current = data[doc[trackable_id]]

          current[:count][action] ||= 0
          current[:count][action] += 1
        end

        # Save summery data
        data.inject([]) do |rs, record|
          rs << Config.summery_class.create(data[record.first])
        end
      end
      
      def last
        self.first(:descending => true)
      end
      
      # Return count for any couchdb view view that has a simple reduce sum(v)
      def count(view = :all, *args, &block)
        if view == :all
          return super({}, *args) 
        end
        
        if has_view?(view)
          query = args.shift || {}
          result = view(view, {:reduce => true}.merge(query), *args, &block)['rows']
        
          return result.first['value'] unless result.empty?
        end
        0
      end
    end
    
    def generate_uuid
      if self[:created_at]
        time = self.delete('created_at')
      else
        time = Time.now
      end
      (@seq ||= SimpleStats::SeqID.new(time)).call
    end
    
    def created_at
      Time.at(self.id[0, 12].to_i(16) / 1000.to_f)
    end
    
    def save(bulk = true)
      super
    end
  end
end
