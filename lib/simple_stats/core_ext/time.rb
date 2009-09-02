class Time 
  
  def self.from_base16_timstamp(timestamp)
    timestamp
  end
  
  def every(interval = 1)
    self.dup - (self.to_i % interval)
  end
  
  def to_js_timestamp
    (self.utc.to_f * 1000).to_i
  end
  
end