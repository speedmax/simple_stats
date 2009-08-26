require File.dirname(__FILE__) + "/../../spec_helper"

describe SimpleStats::Tracking::Source do
  
  before do
    @video = Video.new
    @video.id = rand(1000)
    
    @user = User.new
    @user.id = rand(1000)
  end
  
  describe "tracking methods" do
    it "should have tracking methods for default actions" do
      [:track_impression_on, :track_click_on].each do |action|
        @user.respond_to?(action).should == true
      end
    end

    it "should have generate two-way traching method (target + source)" do

      record = @user.track_impression_on(@video)
      record.target_id.should == @video.id
      record.source_id.should == @user.id
      record.action.should == 'impression'
      
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
      @user.impressions.count.should == 1
      
      # Yesterday
      Time.stub!(:now){ Time.new - 1.day }
      @user.track_impression_on(@video)
      @user.impressions.count.should_not == 2
      
      Time.stub!(:now){ Time.new }
      @user.impressions.count.should == 1
    end
    
    it "should be able to get all stats records with in a date range (ie: item.clicks)" do
      # today
      @user.track_impression_on(@video)
      
      # yesterday
      Time.stub!(:now){ Time.new - 1.day }
      @user.track_impression_on(@video)
      
      # a week before
      Time.stub!(:now){ Time.new - 1.week }
      @user.track_impression_on(@video)
  
      # a year before
      Time.stub!(:now) { Time.new - 1.year }
      @user.track_impression_on(@video)
  
      # Forward in time
      Time.stub!(:now) { Time.new }
      @user.impressions(1.week.ago ... Time.now).count.should == 3
    end
    
    it "should be able to hit count within a date range (ie: item.clicks_count)" do
      
      2.times { @user.track_click_on(@video) }
      @user.clicks_count.should == 2
      @user.clicks.count.should == @user.clicks_count
      
      # Travel back in time and do some impression hits
      Time.stub!(:now) { Time.new - 1.week }
      3.times { @video.track_impression_by(@user) }
      
      # All impressions this week
      this_week = 1.week.ago ... Time.new
      
      @video.impressions_count(this_week).should == 3
      @video.impressions(this_week).count.should == 3
    end


    it "should privide hourly count (ie: item.clicks_by_hour)" do

      Time.stub!(:now) { Time.new - 20.hours }
      2.times{ @user.track_impression_on(@video) }
      
      Time.stub!(:now) { Time.new - 10.hours }
      2.times{ @user.track_impression_on(@video) }
      
      result = @user.impressions_by_hour(3.days.ago ... Time.now)

      result.keys.should == [
        (Time.new - 20.hours).to_json[1, 13],
        (Time.new - 10.hours).to_json[1, 13]
      ]
      result.values.should == [2, 2]
    end
  end
end