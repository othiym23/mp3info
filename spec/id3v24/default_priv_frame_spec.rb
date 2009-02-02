$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::PRIVFrame, "when creating a new PRIV (private data) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    # Base64 encode the data because for this test I want to test the defaults, not binary storage
    @random_data = Base64::encode64(random_string)
    tag = { "PRIV" => ID3V24::Frame.create_frame("PRIV", @random_data) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['PRIV']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::PRIVFrame
  end
  
  it "should default to being owned by me (sure, why not?)" do
    @saved_frame.owner.should == 'mailto:ogd@aoaioxxysz.net'
  end
  
  it "should retrieve the stored private data correctly" do
    @saved_frame.value.should == @random_data
  end
  
  it "should produce a useful pretty-printed representation" do
    @saved_frame.to_s_pretty.should == "PRIVATE DATA (from mailto:ogd@aoaioxxysz.net) [#{@random_data.inspect}]"
  end
end
