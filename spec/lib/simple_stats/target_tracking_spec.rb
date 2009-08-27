require File.dirname(__FILE__) + "/../../spec_helper"

describe SimpleStats::Tracking do
  
  before do
    @item = Item.new
    @item.id = rand(1000)
    
    @user = User.new
    @user.id = rand(1000)
  end
  
  describe "Target tracking" do
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
        clicks clicks_count clicks_by_minute clicks_by_hour clicks_by_day clicks_by_month clicks_by_year
      )

      default_actions.each do |action|
        @item.respond_to?(action).should == true
      end
    end
    
    it "should get state record entries (ie: item.clicks) and using today as default daterange" do
      # A new impression hit
      @item.track_impression
      @item.impressions.length.should == 1
      
      # Yesterday
      Time.stub!(:now) { Time.new - 1.day}
      @item.impressions.length.should_not == 2
      
      Time.stub!(:now) { Time.new }
      @item.impressions.length.should == 1
    end

    it "should be able to get all stats records with in a date range (ie: item.clicks)" do
      # today
      @item.track_impression
      
      # yesterday
      Time.stub!(:now) { Time.new - 1.day }
      @item.track_impression
      
      # a week before
      Time.stub!(:now){ Time.new - 1.week }
      @item.track_impression
  
      # a year before
      Time.stub!(:now) { Time.new - 1.year }
      @item.track_impression
  
      # Forward in time
      Time.stub!(:now) { Time.new }
      @item.impressions(1.week.ago ... Time.now).should have(3).things
  
    end
    
    it "should be able to hit count within a date range (ie: item.clicks_count)" do
      
      2.times { @item.track_click }
      @item.clicks_count.should == 2
      @item.clicks.length.should == @item.clicks_count
      
      # Travel back in time and do some impression hits
      Time.stub!(:now) { Time.new - 1.week }
      2.times { @item.track_impression }
      
      # All impressions this week
      @item.impressions_count(1.week.ago ... Time.now).should == 2
      @item.impressions(1.week.ago ... Time.now).length.should == @item.impressions_count
    end

    it "should privide hourly count (ie: item.clicks_by_hour)" do
      Time.stub!(:now) { Time.new - 20.hours }
      2.times{ @item.track_impression }
      
      Time.stub!(:now) { Time.new - 10.hours }
      2.times{ @item.track_impression }
      
      result = @item.impressions_by_hour(1.day.ago ... Time.new)
      
      result.keys.include?( (Time.new - 20.hours).to_json[1, 13] ).should == true
      result.keys.include?( (Time.new - 10.hours).to_json[1, 13] ).should == true
      result.values.should == [2, 2]
    end
    
    it "should privide daily count (ie: item.clicks_by_day)" do
      Time.stub!(:now) { Time.new - 2.day }
      1.times { @item.track_impression }
      
      Time.stub!(:now) { Time.new - 1.day }
      2.times { @item.track_impression }

      @item.impressions_by_day(2.days.ago ... Time.new).values.should == [1,2]
    end

    it "should privide monthly count (ie: item.clicks_by_month)" do
      Time.stub!(:now) { Time.new }
      2.times{ @item.track_impression }

      @item.impressions_by_month.values.should == [2]
    end
  
  end
end
