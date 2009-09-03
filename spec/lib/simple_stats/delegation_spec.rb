require File.dirname(__FILE__) + "/../../spec_helper"

describe SimpleStats::Delegation do
  before :all do
    reset_test_db!
    
    Time.stub!(:now) {Time.new - 10.minutes}

    
    @user = User.new
    @user.id = rand(100)
    @user.items = (1..10).inject([]) {|items, id|
      item = Item.new
      item.id = id + 1
      item.track_impression
      
      items << item
    }
    
    Time.stub!(:now) { Time.new }
    SimpleStats::Summery.build
  end
  
  describe "Delegate query method" do
    it "should return stats records (ie: website.page_clicks) " do
      @user.items_impressions.should have(10).things
    end
    
    it "should return stats records count (ie: website.page_clicks_count) " do
      @user.items_impressions_count.should == 10
      @user.items_impressions_count.should == @user.items_impressions.length
    end
    
    it "should return stats records by time (ie: website.page_clicks_by_minute)" do
      @user.items_impressions_by_minute.first.last.should == 10
    end
  end
  
  describe "Nested Delegation" do
    it "should be able to delegate to 2 levels deep" do
      @group = Group.new
      @group.users = [@user, @user]
      @group.items_impressions_count.should == 20
    end
  end
  
  describe "Delegation prefix" do

    before :all do
      @user2 = User2.new
      @user2.items = @user.items.dup
    end

    it "should use :to as :prefix no :prefix option is set" do
      @user.respond_to?(:items_impressions).should == true
    end
    
    it "should not use prefix the delegated methods if :prefix => false" do
      @user2.respond_to?(:items_impressions).should == false
      @user2.respond_to?(:impressions).should == true
    end
    
    it "should use custom prefix if prefix option is set" do
      @user2.respond_to?(:ur_mama_impressions).should == true
      @user2.respond_to?(:target_impressions).should == false
    end
  end
end

class User2
  include SimpleStats::Extension
  attr_accessor :items
  
  delegate_stats :to => :items, :prefix => false
  delegate_stats :to => :target, :prefix => 'ur_mama'
  
  def target
    items
  end
end

class Group
  include SimpleStats::Extension
  
  delegate_stats :to => :items
  attr_accessor :users

  def items
    users.map(&:items).flatten
  end
  
end