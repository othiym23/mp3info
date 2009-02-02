$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::COMMFrame, "when creating a new COMM (comment) frame customized for ::AOAIOXXYSZ::" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @comment_text = "Track 5"
    comm = ID3V24::Frame.create_frame("COMM", @comment_text)
    comm.description = '::AOAIOXXYSZ:: Info'
    tag = { "COMM" => comm }
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
  
  it "should describe itself as an '::AOAIOXXYSZ:: Info' frame" do
    @saved_frame.description.should == '::AOAIOXXYSZ:: Info'
  end
  
  it "should default to being in English (sorry, non-English-speaking world)" do
    @saved_frame.language.should == 'eng'
  end
  
  it "should default having a pretty format identical to id3v2's" do
    @saved_frame.to_s_pretty.should == "(::AOAIOXXYSZ:: Info)[eng]: Track 5"
  end
  
  it "should retrieve the stored comment value correctly" do
    @saved_frame.value.should == @comment_text
  end
  
  it "should produce output identical to id3v2's when compared" do
    test_against_id3v2_prog(@saved_tag).should == prettify_tag(@saved_tag)
  end
end
