$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::XDORFrame, "when dealing with the iTunes and ID3v2.3-specific XDOR (date of release) frame" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @release_date = Time.gm(1993, 3, 8)
    tag = { "XDOR" => ID3V24::Frame.create_frame("XDOR", @release_date) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['XDOR']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should convert the release date to a known value captured from an iTunes-created file" do
    xdor = ID3V24::Frame.create_frame("XDOR", Time.gm(1993, 3, 8))
    xdor.encoding = ID3V24::TextFrame::ENCODING[:utf16]
    xdor.to_s.should == "\001\376\377\0001\0009\0009\0003\000-\0000\0003\000-\0000\0008\000\000"
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::XDORFrame
  end
  
  it "should reconstitute the release date properly" do
    @saved_frame.value.should == @release_date
  end
  
  it "should pretty-print the release date as an RFC-compliant date" do
    @saved_frame.to_s_pretty.should == "Release date: Mon, 08 Mar 1993 00:00:00 -0000"
  end
end
