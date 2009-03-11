# encoding: binary
$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::RGADFrame, "when creating a new RGAD (replay gain) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @gain = 4.3
    tag = { "RGAD" => ID3V24::Frame.create_frame("RGAD", @gain) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['RGAD']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should reconstitute itself as the correct class" do
    @saved_frame.class.should == ID3V24::RGADFrame
  end
  
  it "should be valid" do
    @saved_frame.track_gain.valid?.should be_true
    @saved_frame.album_gain.valid?.should be_true
    @saved_frame.valid?.should be_true
  end
  
  it "should show the track gain adjustment of being the 'track' type" do
    @saved_frame.track_gain.type.should == 'track'
  end
  
  it "should show the track gain adjustment as having an origin of 'automatic'" do
    @saved_frame.track_gain.origin.should == 'automatic'
  end
  
  it "should preserve the track gain adjustment set within a tolerance of the epsilon for the adjustment (0.001953125)" do
    @saved_frame.track_gain.adjustment.should == @gain
  end
  
  it "should correctly calculate the raw track gain adjustment value based on the dB value passed to the default generator" do
    @saved_frame.track_gain.raw_adjustment.should == 43
  end
  
  it "should show the album gain adjustment of being the 'album' type" do
    @saved_frame.album_gain.type.should == 'album'
  end
  
  it "should show the album gain adjustment as having an origin of 'automatic'" do
    @saved_frame.album_gain.origin.should == 'automatic'
  end
  
  it "should preserve the album gain adjustment set within a tolerance of the epsilon for the adjustment (0.001953125)" do
    @saved_frame.album_gain.adjustment.should == @gain
  end
  
  it "should correctly calculate the raw album gain adjustment value based on the dB value passed to the default generator" do
    @saved_frame.album_gain.raw_adjustment.should == 43
  end
  
  it "should have a peak amplitude of 0.0" do
    @saved_frame.peak == 0.0
  end
  
  it "should correctly encode itself to binary" do
    @saved_frame.to_s.should == "\x00\x00\x00\x00\x2c\x2b\x4c\x2b"
  end
end
