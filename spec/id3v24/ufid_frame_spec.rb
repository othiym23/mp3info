$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::UFIDFrame, "when creating a new UFID (unique file identifier) frame" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @ufid = "2451-4235-af32a3-1312"
    tag = { "UFID" => ID3V24::Frame.create_frame("UFID", @ufid) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['UFID']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::UFIDFrame
  end
  
  it "has no default namespace, but uses 'http://www.id3.org/dummy/ufid.html' instead" do
    @saved_frame.namespace.should == "http://www.id3.org/dummy/ufid.html"
  end
  
  it "should retrieve the stored ID unmolested" do
    @saved_frame.value.should == @ufid
  end
  
  it "should pretty-print the unique ID as namespace: \"ID\"" do
    @saved_frame.to_s_pretty.should == 'http://www.id3.org/dummy/ufid.html: "2451-4235-af32a3-1312"'
  end
end
