# encoding: binary
$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::RGADFrame, "when working directly with RGAD frame gain adjustments" do
  it "should have a minimum positive gain increment of 0.1 dB" do
    frame = ID3V24::RGADFrame.default(0)
    # need to do it this way so I can directly set the raw adjustment
    gain = frame.album_gain
    gain.raw_adjustment = 1
    frame.album_gain = gain
    
    frame.album_gain.raw_adjustment.should == 1
    frame.album_gain.to_bin.should == "\x4c\x01"
    frame.album_gain.adjustment.should == 0.1
  end
  
  it "should have a maximum positive gain adjustment of 25.5 dB" do
    frame = ID3V24::RGADFrame.default(0)
    # need to do it this way so I can directly set the raw adjustment
    gain = frame.album_gain
    gain.raw_adjustment = 255
    frame.album_gain = gain
    
    frame.album_gain.raw_adjustment.should == 255
    frame.album_gain.to_bin.should == "\x4c\xff"
    frame.album_gain.adjustment.should == 25.5
  end
  
  it "should have a minimum negative gain increment of -0.1 dB" do
    frame = ID3V24::RGADFrame.default(0)
    # need to do it this way so I can directly set the raw adjustment
    gain = frame.track_gain
    gain.raw_adjustment = -1
    frame.track_gain = gain
    
    frame.track_gain.raw_adjustment.should == -1
    frame.track_gain.to_bin.should == "\x2e\x01"
    frame.track_gain.adjustment.should == -0.1
  end
  
  it "should have a maximum negative gain adjustment of -25.5 dB" do
    frame = ID3V24::RGADFrame.default(0)
    # need to do it this way so I can directly set the raw adjustment
    gain = frame.track_gain
    gain.raw_adjustment = -255
    frame.track_gain = gain
    
    frame.track_gain.raw_adjustment.should == -255
    frame.track_gain.to_bin.should == "\x2e\xff"
    frame.track_gain.adjustment.should == -25.5
  end
  
  it "should be able to set the track adjustment's origin as 'preset'" do
    frame = ID3V24::RGADFrame.default(1.3)
    gain = frame.track_gain
    gain.origin_code = ID3V24::RGADAdjustment::ORIGIN_PRESET
    frame.track_gain = gain
    
    frame.track_gain.to_bin.should == "\x24\x0d"
    frame.track_gain.origin.should == 'preset'
  end
  
  it "should be able to set the album adjustment's origin as 'user'" do
    frame = ID3V24::RGADFrame.default(1.3)
    gain = frame.album_gain
    gain.origin_code = ID3V24::RGADAdjustment::ORIGIN_USER
    frame.album_gain = gain
    
    frame.album_gain.to_bin.should == "\x48\x0d"
    frame.album_gain.origin.should == 'user'
  end
  
  it "should be able to set the track adjustment's type as 'album', while invalidating the frame" do
    frame = ID3V24::RGADFrame.default(1.3)
    gain = frame.track_gain
    gain.type_code = ID3V24::RGADAdjustment::TYPE_AUDIOPHILE
    frame.track_gain = gain
    
    frame.track_gain.valid?.should be_true
    frame.track_gain.to_bin.should == "\x4c\x0d"
    frame.track_gain.type.should == 'album'
    frame.valid?.should be_false
  end
  
  it "should be able to set the album adjustment's type as 'track', while invalidating the frame" do
    frame = ID3V24::RGADFrame.default(1.3)
    gain = frame.album_gain
    gain.type_code = ID3V24::RGADAdjustment::TYPE_RADIO
    frame.album_gain = gain
    
    frame.album_gain.valid?.should be_true
    frame.album_gain.to_bin.should == "\x2c\x0d"
    frame.album_gain.type.should == 'track'
    frame.valid?.should be_false
  end
end

describe ID3V24::RGADFrame, "when parsing a constructed RGAD (nonstandard ID3v2 replaygain) frame" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @rgad = "\x93\x18\x7c\x3f\x2a\x14\x4c\x14"
    tag = { "RGAD" => ID3V24::Frame.create_frame_from_string("RGAD", @rgad) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['RGAD']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should be reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::RGADFrame
  end
  
  it "should be valid" do
    @saved_frame.valid?.should be_true
  end
  
  it "should have a peak amplitude of 0.98475" do
    @saved_frame.peak.should be_close(0.98475, 0.00001)
  end
  
  it "should have a valid track gain adjustment" do
    @saved_frame.track_gain.valid?.should be_true
  end
  
  it "should have a track gain adjustment type of 'track'" do
    @saved_frame.track_gain.type.should == 'track'
  end
  
  it "should have a track gain adjustment origin of 'user'" do
    @saved_frame.track_gain.origin.should == 'user'
  end
  
  it "should have a track gain adjustment value of -2 dB" do
    @saved_frame.track_gain.adjustment.should == -2.0
  end
  
  it "should have a track gain raw adjustment value of -20" do
    @saved_frame.track_gain.raw_adjustment.should == -20
  end
  
  it "should have a valid album gain adjustment" do
    @saved_frame.album_gain.valid?.should be_true
  end
  
  it "should have an album gain adjustment type of 'album'" do
    @saved_frame.album_gain.type.should == 'album'
  end
  
  it "should have an album gain adjustment origin of 'automatic'" do
    @saved_frame.album_gain.origin.should == 'automatic'
  end
  
  it "should have an album gain adjustment value of -2 dB" do
    @saved_frame.album_gain.adjustment.should == 2.0
  end
  
  it "should have an album gain raw adjustment value of -20" do
    @saved_frame.album_gain.raw_adjustment.should == 20
  end
end
