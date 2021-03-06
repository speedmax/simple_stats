module SimpleStats
  class Record < CouchRest::ExtendedDocument
    include CouchRest::Validation

    view_by :accessed_at, 
      :map => 
        "function(doc) {
          if ((doc['couchrest-type'] == 'SimpleStats::Record') && doc['accessed_at']) {
            emit(doc['accessed_at'], null);
          }
        }"

    view_by :action, :source_id, :accessed_at,
      :map => 
        "function(doc) {
          if ((doc['couchrest-type'] == 'SimpleStats::Record') && doc.action && doc.source_id && doc.source_type && doc.accessed_at) {
            emit([doc.action, doc.source_id, doc.source_type, doc.accessed_at], 1);
          }
        }",
      :reduce => "function(k, v) {return sum(v);}"
      
    view_by :action, :target_id, :accessed_at,
      :map => 
        "function(doc) {
          if ((doc['couchrest-type'] == 'SimpleStats::Record') && doc.action && doc.target_id && doc.target_type &&doc.accessed_at) {
            emit([doc.action, doc.target_id, doc.target_type, doc.accessed_at], 1);
          }
        }",
      :reduce => "function(k, v) {return sum(v);}"
    
    unique_id :generate_uuid
    
    # Schema
    property :target_type
    property :target_id
    
    property :source_type
    property :source_id

    property :action
    property :accessed_at

    property :request_uri
    property :user_agent
    property :remote_ip
    property :referer
    property :meta

    # Validations
    validates_present :action, :target_id
    validates_with_method :ensure_valid_action

    # Callbacks
    save_callback :before, :generate_accessed_at
    
    
    class << self
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
    # 
    # def generate_uuid
    #   (@seq ||= SimpleStats::SeqID.new).call
    # end
    
    def generate_uuid
      if self[:accessed_at]
        time = self[:accessed_at]
      else
        time = Time.now
      end
      (@seq ||= SimpleStats::SeqID.new(time)).call
    end
    
    # Javascript compatible timestamp
    def timestamp
      id[0,12].to_i(16)
    end
    
    def created_time
      Time.at(timestamp/ 1000.0) rescue nil
    end

  private
    def ensure_valid_action
      result = Config.supported_actions.include?(self['action'])
      
      [result,"Invalid action #{self['action']}"]
    end
  
    def generate_accessed_at
      self['accessed_at'] = Time.now if new_record? && self['accessed_at'].blank?
    end
  end
end