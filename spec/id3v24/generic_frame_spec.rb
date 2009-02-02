$:.unshift("spec/")

require 'digest/sha1'
require 'mp3info/mp3info_helper'

describe ID3V24::Frame, "when working with individual frames" do
  include Mp3InfoHelper
  
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @trivial_id3v2_tag = {"TIT2" => ID3V24::Frame.create_frame('TIT2', "sdfqdsf")}
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should create a raw frame when given an unknown frame ID" do
    ID3V24::Frame.create_frame('XXXX', 0).class.should == ID3V24::Frame
  end
  
  it "should gracefully handle unknown frame types" do
    crud = random_string
    tag = { "XNXT" => ID3V24::Frame.create_frame("XNXT", crud) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    saved_tag['XNXT'].class.should == ID3V24::Frame
    saved_tag['XNXT'].value.size.should == crud.size
    Digest::SHA1.hexdigest(saved_tag['XNXT'].to_s_pretty).should == Digest::SHA1.hexdigest(crud)
    saved_tag['XNXT'].frame_info.should == "No description available for frame type 'XNXT'."
  end
  
  it "should create a generic text frame when given an unknown Txxx frame ID" do
    ID3V24::Frame.create_frame('TPOS', '1/14').class.should == ID3V24::TextFrame
  end

  it "should create a link frame when given an unknown Wxxx frame ID" do
    ID3V24::Frame.create_frame('WOAR', 'http://www.dresdendolls.com/').class.should == ID3V24::LinkFrame
  end

  it "should create a custom frame type when given a custom ID (TCON)" do
    ID3V24::Frame.create_frame('TCON', 'Experimetal').class.should == ID3V24::TCONFrame
  end
  
  it "should correctly retrieve the description for the conductor frame" do
    tag = { "TPE3" => ID3V24::Frame.create_frame("TPE3", "Leopold Stokowski") }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    saved_tag['TPE3'].class.should == ID3V24::TextFrame
    saved_tag['TPE3'].value.should == "Leopold Stokowski"
    saved_tag['TPE3'].to_s_pretty.should == "Leopold Stokowski"
    saved_tag['TPE3'].frame_info.should ==  "The 'Conductor' frame is used for the name of the conductor."
  end
  
  it "should correctly retrieve the description for the original audio link frame" do
    tag = { "WOAF" => ID3V24::Frame.create_frame("WOAF", "http://example.com/audio.html") }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    saved_tag['WOAF'].class.should == ID3V24::LinkFrame
    saved_tag['WOAF'].value.should == "http://example.com/audio.html"
    saved_tag['WOAF'].to_s_pretty.should == "URL: http://example.com/audio.html"
    saved_tag['WOAF'].frame_info.should == "The 'Official audio file webpage' frame is a URL pointing at a file specific webpage."
  end
  
  it "should correctly store lots of binary data in a frame" do
    tag = {"APIC" => ID3V24::Frame.create_frame("APIC", random_string) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    saved_tag['APIC'].value.size.should == Mp3InfoHelper::TEST_PRIME
    saved_tag.should == tag
  end
end
