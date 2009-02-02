$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::COMMFrame, "when creating a new COMM (comment) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @comment_text = "This is a sample comment."
    tag = { "COMM" => ID3V24::Frame.create_frame("COMM", @comment_text) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['COMM']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::COMMFrame
  end
  
  it "should choose a default encoding for the description of the image of UTF-16" do
    @saved_frame.encoding.should == ID3V24::TextFrame::ENCODING[:utf16]
  end
  
  it "should have a default description of 'Mp3Info Comment'" do
    @saved_frame.description.should == 'Mp3Info Comment'
  end
  
  it "should default to being in English (sorry, non-English-speaking world)" do
    @saved_frame.language.should == 'eng'
  end
  
  it "should default having a pretty format identical to id3v2's" do
    @saved_frame.to_s_pretty.should == "(Mp3Info Comment)[eng]: This is a sample comment."
  end
  
  it "should retrieve the stored comment value correctly" do
    @saved_frame.value.should == @comment_text
  end
  
  it "should produce output identical to id3v2's when compared" do
    test_against_id3v2_prog(@saved_tag).should == prettify_tag(@saved_tag)
  end
end
