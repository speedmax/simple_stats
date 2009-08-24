require File.dirname(__FILE__) + "/../../spec_helper"

describe SimpleStats::TargetTracking do
  
  before do
    @item = Item.new
    @item.id = rand(1000)
    
    @user = User.new
    @user.id = rand(1000)
  end
  
  describe "tracking methods" do
    it "should have tracking methods for default actions" do
      [:track_impression, :track_click].each do |action|
        @item.respond_to?(action).should == true
      end
    end
    
    it "should have standard tracking method for target-only" do
      reset_test_db!
      
      record  = @item.track_impression
      record.target_id.should == @item.id
      record.action.should == 'impression'
      
      @item.impressions_count.should == 1
      
      record  = @item.track_click
      record.target_id.should == @item.id
      record.action.should == 'click'
      
      @item.clicks_count.should == 1
    end
    
    it "should have generate two-way traching method (target + source)" do
      record = @item.track_impression_by(@user)
      record.target_id.should == @item.id
      record.source_id.should == @user.id
      record.action.should == 'impression'
      
      @item.impressions_count.should == 1
      @user.impressions_count.should == 1
    end
  end
  
  describe "query methods" do
    it "should have generated query methods for default actions" do
      default_actions = %w(
        impressions impressions_count impressions_timestamps
        clicks clicks_count clicks_timestamps)
        
      default_actions.each do |action|
        @item.respond_to?(action).should == true
      end
    end
    
    it "should be able to retrive using today as default date range" do
      # A new impression hit
      @item.track_impression
      @item.impressions.count.should == 1
      
      # Yesterday
      Time.stub!(:now).and_return(Time.new - 1.day)
      @item.track_impression
      @item.impressions.count.should_not == 2
      
      Time.stub!(:now).and_return(Time.new)
      @item.impressions.count.should == 1
    end

    it "should be able to get all stats records with in a date range (ie: item.clicks)" do
      # today
      @item.track_impression
      
      # yesterday
      Time.stub!(:now).and_return(Time.new - 1.day)
      @item.track_impression
      
      # a week before
      Time.stub!(:now).and_return(Time.new - 1.week)
      @item.track_impression

      # a year before
      Time.stub!(:now).and_return(Time.new - 1.year)
      @item.track_impression

      # Forward in time
      Time.stub!(:now).and_return(Time.new)
      @item.impressions(1.week.ago ... Time.now).count.should == 3

    end
    
    it "should be able to hit count within a date range (ie: item.clicks_count)" do
      
      10.times { @item.track_click }
      @item.clicks_count.should == 10
      @item.clicks.count.should == @item.clicks_count
      
      # Travel back in time and do some impression hits
      Time.stub!(:now).and_return(Time.new - 1.week)
      10.times { @item.track_impression }
      
      # All impressions this week
      @item.impressions_count(1.week.ago ... Time.now).should == 10
      @item.impressions(1.week.ago ... Time.now).count.should == @item.impressions_count
    end
    
    it "should be able to get all row timestamps for tasks like charting  (ie: item.clicks_timestamps)" do
      10.times { @item.track_impression }
      @item.impressions_timestamps.count == 10
      
      lambda{
        Time.parse(@item.impressions_timestamps.first)
      }.should_not raise_error
    end

    it "should be able to accept custom date range" do
      # today
      @item.track_impression
      
      # yesterday
      Time.stub!(:now).and_return(Time.new - 1.day)
      @item.track_impression
      
      # a week before
      Time.stub!(:now).and_return(Time.new - 1.week)
      @item.track_impression

      # a year before
      Time.stub!(:now).and_return(Time.new - 1.year)
      @item.track_impression

      # Forward in time
      Time.stub!(:now).and_return(Time.new)
      
      # All impressions this week
      @item.impressions(1.week.ago ... Time.now).count.should == 3           
    end

  end
  
end