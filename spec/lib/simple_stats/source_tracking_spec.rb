require File.dirname(__FILE__) + "/../../spec_helper"

describe SimpleStats::Tracking::Source do
  
  before :all do
    @video = mock_model('Video')
    @user = mock_model('User')
    
    SimpleStats::Config.setup
    SimpleStats::Config.query_method = :aggregated
  end
  
  describe "tracking methods" do
    it "should have tracking methods for default actions" do
      [:track_impression_on, :track_click_on].each do |action|
        @user.respond_to?(action).should == true
      end
    end

    it "should have generate two-way traching method (target + source)" do
      Time.stub!(:now) { Time.new - 10.minutes }
      record = @user.track_impression_on(@video)
      record.target_id.should == @video.id
      record.source_id.should == @user.id
      record.action.should == 'impression'
      
      Time.stub!(:now) { Time.new }
      SimpleStats::Summery.build
      
      @video.impressions_count.should == 1
      @user.impressions_count.should == 1
    end
  end
 
  describe "query methods" do
    it "should have generated query methods for default actions" do
     default_actions = %w(
       impressions impressions_count
       clicks clicks_count)
 
     default_actions.each do |action|
       @user.respond_to?(action).should == true
     end
    end
    
    it "should be able to retrive using today as default date range" do
      # A new impression hit
      @user.track_impression_on(@video)
      @user.impressions.length.should == 1
      
      # Yesterday
      Time.stub!(:now) { Time.new - 1.day }

      @user.track_impression_on(@video)
      @user.impressions.length.should_not == 2
      
      Time.stub!(:now){ Time.new }
      @user.impressions.length.should == 1
    end
    
    it "should be able to get all stats records with in a date range (ie: item.clicks)" do
      reset_test_db!
      # today
      Time.stub!(:now) { Time.new }
      @user.track_impression_on(@video)
      
      # yesterday
      Time.stub!(:now){ Time.new - 1.day }
      @user.track_impression_on(@video)
      
      # a week before
      Time.stub!(:now){ Time.new - 1.week }
      @user.track_impression_on(@video)
  
      # a year before
      Time.stub!(:now) { Time.new - 1.month }
      @user.track_impression_on(@video)
  
      # Forward in time
      Time.stub!(:now) { Time.new + 1.minutes }
      SimpleStats::Summery.build(10.minutes)
      
      @user.impressions(2.week.ago ... Time.now).length.should == 3
    end
    
    it "should be able to hit count within a date range (ie: item.clicks_count)" do
      reset_test_db!
      
      Time.stub!(:now) { Time.new - 1.week }
      2.times { @user.track_click_on(@video) }
      
      Time.stub!(:now) { Time.new - 20.minutes }

      # Travel back in time and do some impression hits
      3.times { @video.track_impression_by(@user) }
      
      # All impressions this week
      this_week = 1.week.ago ... Time.new

      Time.stub!(:now) { Time.new }
      SimpleStats::Summery.build

      @user.clicks_count(this_week).should == 2
      @user.clicks(this_week).length.should == @user.clicks_count(this_week)
            
      @video.impressions_count.should == 3
      @video.impressions.length.should == 3
    end

    it "should privide hourly count (ie: item.clicks_by_hour)" do
      reset_test_db!
      
      Time.stub!(:now) { Time.new - 4.hours }
      2.times{ @user.track_impression_on(@video) }
      
      Time.stub!(:now) { Time.new - 2.hours }
      2.times{ @user.track_impression_on(@video) }
      
      Time.stub!(:now) { Time.new + 1.hour}
      SimpleStats::Summery.build(1.hour)

      result = @user.impressions_by_hour(1.day.ago ... Time.now)
      
      result.keys.include?( (Time.new - 4.hours).to_json[1, 13] ).should == true
      result.keys.include?( (Time.new - 2.hours).to_json[1, 13] ).should == true
      result.values.should == [2, 2]
    end
  end
end