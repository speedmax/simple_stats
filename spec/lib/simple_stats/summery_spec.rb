require File.dirname(__FILE__) + "/../../spec_helper"

include SimpleStats

describe SimpleStats::Summery do
  before do
    SimpleStats::Config.setup
    
    @item = mock_model('Item')
    @user = mock_model('User')
    @start_time =  Time.parse('2008-10-10 12:00:00 +0000').utc
    @interval = SimpleStats::Config.summery_interval
    @padding = SimpleStats::Config.summery_padding
  end
  
  it "should build sumerized stats report for tracking target" do
    @item.track_impression
    
    Summery.build_for(:target, 10.seconds.ago .. Time.now)
    Summery.count.should == 1
    
    # Check summery record
    first_record = Summery.first
    first_record.type.should == 'target'
    first_record.trackable_type.should == @item.class.to_s
    first_record.trackable_id.should == @item.id
  end
  
  it "should build sumerized stats for tracking source" do
    reset_test_db!
    
    @item.track_click_by(@user)
    Summery.build_for(:target, 10.seconds.ago .. Time.now)
    Summery.build_for(:source, 10.seconds.ago .. Time.now)
  
    Summery.count.should == 2
    # check summery record
    last_record = Summery.last
    last_record.type.should == 'source'
    last_record.trackable_type.should == @user.class.to_s
    last_record.trackable_id.should == @user.id
  end
  
  describe "Expiration" do
    it "should be expired if there are no summery record" do
      reset_test_db!
      @item.track_impression
      
      Summery.expired?(@interval).should == true
    end
  
    it "should be false if a summery record just been saved recently" do
      reset_test_db!
      Time.stub!(:now){ @start_time }
    
      # Create a summery record at this time (minus padding time)
      Summery.create(:created_at => @start_time)
      Summery.expired?(@interval).should == false
      
      # if time advance 9:59 expired should be false
      Time.stub!(:now){ @start_time + @interval }
      Summery.expired?(@interval).should == false
    end
  
    it "should return expired if time has advanced more than the interval " do
      reset_test_db!
      Time.stub!(:now){ @start_time }
    
      # Create a summery record at this time (minus padding time)
      Summery.create(:created_at => @start_time)
      Summery.expired?(@interval).should == false
  
      # if time advanced more than interval, expired should be true
      Time.stub!(:now){ @start_time + @interval + @padding }
      Summery.expired?(@interval).should == true
    end
  end
  
  describe "Building process" do
    it "should build all stats summery from first stats record if no summery record exists " do
      reset_test_db!
      
      log_it = lambda{ @item.track_impression(:accessed_at => Time.now + rand(10).seconds) }
      
      Time.stub!(:now){ @start_time }
      2.times{ log_it.call }
  
      Time.stub!(:now){ @start_time.advance(:minutes => 10) }
      2.times{ log_it.call }
  
      Time.stub!(:now){ @start_time.advance(:minutes => 20) }
      2.times{ log_it.call }
      
      # Forward 21 minutes
      Time.stub!(:now){ @start_time.advance(:minutes => 21) }
      Summery.expired?(@interval).should == true
      Summery.build(@interval)
  
      total_impression = Summery.all.map{|s| s.count["impression"]}.flatten.sum
      total_impression = 6
    end
    
    it "should build stats summery from last summery record" do
      reset_test_db!
      log_it = lambda{ @item.track_impression(:accessed_at => Time.now + rand(10).seconds) }
  
      Time.stub!(:now){ @start_time }
      5.times{ log_it.call }
      
      # Build summery for stats
      Time.stub!(:now){ @start_time + @interval + @padding}
      Summery.build(@interval).should_not be_empty
      Summery.count.should == 1
  
      Time.stub!(:now){ @start_time.advance(:minutes => 10) }
      5.times{ log_it.call }
  
      # Forward 11 minutes and build from there
      Time.stub!(:now){ @start_time.advance(:minutes => 21) }
      Summery.build(@interval).should_not be_empty
      Summery.count.should == 2
      
      total_impression = Summery.all.map{|s| s.count["impression"]}.flatten.sum
      total_impression = 10
    end
  end
  
  describe "Query" do
    it "should return stats summery in given priod of time" do
      reset_test_db!
  
      # random time within that week
      Time.stub!(:now){ 
        min = rand(5500).minutes 
        min -= 1.week if min > 1.week
        @start_time + min
      }
    
      20.times { @item.track_impression }
    
      Time.stub!(:now){ @start_time + 1.week }
  
      Summery.build(@interval).should_not be_empty
  
      range = @start_time .. @start_time + 1.week
      results = Summery.by_timestamp_and_type_and_trackable_action(
        :reduce => true,
        :raw => true,
        :group => true,
        :startkey => ['target', 'Item', @item.id, 'impression', range.first.to_js_timestamp],
        :endkey => ['target', 'Item', @item.id, 'impression', range.last.to_js_timestamp]
      )["rows"]
      
      results.map{|r| r["value"]}.flatten.sum.should == 20
    end
    
    it "should start stats update when stats require update" do
      reset_test_db!
      current = @start_time
      
      Time.stub!(:now){ current = current.succ }

      20.times do
        @item.track_impression

        # DO NOT do this in production, only works in single threaded mode
        # Use more robust async processing instead
        if Summery.expired?(1.minute)
          Summery.build(1.minute)
        end
      end

      Time.stub!(:now) { @start_time + 2.week }
      Summery.build(1.minute)

      @item.stats_records_by_year('impression', @start_time .. @start_time + 4.week)

      results = Summery.by_timestamp_and_type_and_trackable_action(
        :reduce => true,
        :raw => true,
        :group => true,
        :startkey => ['target', 'Item', @item.id, 'impression', @start_time.to_js_timestamp],
        :endkey => ['target', 'Item', @item.id, 'impression', (@start_time + 4.week).to_js_timestamp]
      )["rows"]
      
      results.map{|r| r["value"]}.sum.should == 20
    end
  end
end

class Time
  def self.travel(time)
    Time.stub!(:now) { time }
  end
end