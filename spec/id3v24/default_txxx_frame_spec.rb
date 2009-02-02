$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::TXXXFrame, "when creating a new TXXX (user-defined text) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @user_text = "Here is some random user-defined text."
    @new_tag = { "TXXX" => ID3V24::Frame.create_frame("TXXX", @user_text) }
    @saved_tag = update_id3_2_tag(@mp3_filename, @new_tag)
    @saved_frame = @saved_tag['TXXX']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::TXXXFrame
  end
  
  it "should be saved as UTF-16 Unicode text with a byte-order mark by default" do
    @saved_frame.encoding.should == ID3V24::TextFrame::ENCODING[:utf16]
  end
  
  it "should have 'Mp3Info Comment' as its default description (this should be overridden in practice)" do
    @saved_frame.description.should == 'Mp3Info Comment'
  end
  
  it "should safely retrieve its value" do
    @saved_frame.value.should == @user_text
  end
  
  it "should be directly comparable as a whole frame" do
    @saved_frame.should == @new_tag['TXXX']
  end
  
  it "should pretty-print in the style of id3v2" do
    @saved_frame.to_s_pretty.should == "(Mp3Info Comment) : Here is some random user-defined text."
  end
end
