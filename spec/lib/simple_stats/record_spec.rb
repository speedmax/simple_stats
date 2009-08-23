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
    proc{ create_record(:action => 'click') }.should_not raise_error
    
    proc{ create_record }.should raise_error
  end
  
  it "should only accept supported actions" do
    proc{ create_record(:action => 'undefined') }.should raise_error
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