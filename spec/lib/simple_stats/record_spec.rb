require File.dirname(__FILE__) + "/../../spec_helper"

describe SimpleStats::Record do

  it "should be able create new record" do
    record = create_record(:action => 'click')
    record.new_record?.should == false
  end

  it "should be returning correct count of records" do
    reset_test_db!
    SimpleStats::Record.count.should == 0
    
    record  = create_record(:action => 'click')
    SimpleStats::Record.count.should >= 1
  end
  
  it "should validate presence of an action" do
    lambda{ create_record(:action => 'click') }.should_not raise_error
    
    lambda{ create_record }.should raise_error
  end
  
  it "should only accept supported actions" do
    lambda{ create_record(:action => 'undefined') }.should raise_error
  end
  
    
  it "should have set accessed_at using current time" do
    r = create_record(:action => 'impression')
    r.accessed_at.should be_a(Time)
    r.accessed_at.to_date == Date.today
  end
  
  it "should save additional attributes" do
    r = create_record(:action => 'click', :remote_ip => '127.0.0.1', :accessed_at => Time.new - 1.year)
    r.remote_ip.should == '127.0.0.1'
    r.accessed_at.year == 1.year.ago.year
  end

end

def create_record(hash = {})
  SimpleStats::Record.create!(hash.merge(
    :target_id => 1,
    :remote_ip => '127.0.0.1',
    :user_agent => 'rspec test',
    :referer => 'localhost'
  ))
end