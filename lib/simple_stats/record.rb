module SimpleStats
  class Record < CouchRest::ExtendedDocument
    include CouchRest::Validation

    # Views
    view_by :action, :source_id, :accessed_at,
      :map => 
        "function(doc) {
          if ((doc['couchrest-type'] == 'SimpleStat::Record') && doc.action && doc.source_id && doc.accessed_at) {
            emit([doc.action, doc.source_id, doc.accessed_at], 1);
          }
        }",
      :reduce => "function(k, v) {return sum(v);}"
      
    view_by :action, :target_id, :accessed_at,
      :map => 
        "function(doc) {
          if ((doc['couchrest-type'] == 'SimpleStat::Record') && doc.action && doc.target_id && doc.accessed_at) {
            emit([doc.action, doc.target_id, doc.accessed_at], 1);
          }
        }",
      :reduce => "function(k, v) {return sum(v);}"

    # Schema
    property :source_id
    property :target_id

    property :action
    property :accessed_at, :cast_as => Time, :read_only => true

    property :request_uri
    property :user_agent
    property :remote_ip
    property :referrer

    # Validations
    validates_present :action
    validates_with_method :ensure_valid_action

    # Callbacks
    save_callback :before, :generate_accessed_at

    # Return count for any couchdb view view that has a simple reduce sum(v)
    def self.count(view = :all, *args, &block)
      if has_view?(view)
        query = args.shift || {}
        result = view(view, {:reduce => true}.merge(query), *args, &block)['rows']
        
        return result.first['value'] unless result.empty?
      end
      0
    end
    
  private
    def ensure_valid_action
      result = Config.supported_actions.include?(self['action'])
      
      [result,"Invalid action #{self['action']}"]
    end
  
    def generate_accessed_at
      self['accessed_at'] = Time.now if new_document?
    end
  end
end