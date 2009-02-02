$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::WXXXFrame, "when creating a new WXXX (user-defined link) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @user_link = "http://www.yourmom.gov"
    @new_tag = { "WXXX" => ID3V24::Frame.create_frame("WXXX", @user_link) }
    @saved_tag = update_id3_2_tag(@mp3_filename, @new_tag)
    @saved_frame = @saved_tag['WXXX']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::WXXXFrame
  end
  
  it "should have a description encoded as UTF-16 Unicode text with a byte-order mark by default" do
    @saved_frame.encoding.should == ID3V24::TextFrame::ENCODING[:utf16]
  end
  
  it "should have 'Mp3Info User Link' as its default description (this should be overridden in practice)" do
    @saved_frame.description.should == 'Mp3Info User Link'
  end
  
  it "should safely retrieve its value" do
    @saved_frame.value.should == @user_link
  end
  
  it "should be directly comparable as a whole frame" do
    @saved_frame.should == @new_tag['WXXX']
  end
  
  it "should pretty-print in the style of id3v2" do
    @saved_frame.to_s_pretty.should == "(Mp3Info User Link) : http://www.yourmom.gov"
  end
end
