require File.dirname(__FILE__) + "/../../spec_helper"

describe SimpleStats::Delegation do
  before do
    reset_test_db!
    
    @user = User.new
    @user.id = rand(100)
    @user.items = (1..10).inject([]) {|items, id|
      item = Item.new
      item.id = id + 1
      item.track_impression
      
      items << item
    }
  end
  
  describe "Delegate query method" do
    it "should return stats records (ie: website.page_clicks) " do
      @user.items_impressions.should have(10).things
    end
    
    it "should return stats records count (ie: website.page_clicks_count) " do
      @user.items_impressions_count.should == 10
      @user.items_impressions_count.should == @user.items_impressions.count
    end
    
    it "should return stats records by time (ie: website.page_clicks_by_minute)" do
      @user.items_impressions_by_minute.first.last.should == 10
    end
  end
  
  describe "Nested Delegation" do
    before do    
      @group = Group.new
      @group.users = [@user, @user]
    end
    
    it "should be able to delegate to 2 levels deep" do
      @group.items_impressions_count.should == 20
    end
  end
  
  describe "Delegation prefix" do

    it "should use :to as :prefix no :prefix option is set" do
      @user.respond_to?(:items_impressions).should == true
    end
    
    it "should not use prefix the delegated methods if :prefix => false" do
      User.class_eval do
        delegate_stats :to => :target1, :prefix => false
        
        def target1
          items
        end
      end
      
      @user.respond_to?(:target1_impressions).should == false
      @user.respond_to?(:impressions).should == true
    end
    
    it "should use custom prefix if prefix option is set" do
      User.class_eval do
        delegate_stats :to => :target2, :prefix => 'yo_mama'
        
        def target2
          items
        end
      end
      
      @user.respond_to?(:yo_mama_impressions).should == true
    end
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