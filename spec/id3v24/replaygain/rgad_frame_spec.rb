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
    
    expect(frame.album_gain.raw_adjustment).to eq(1)
    expect(frame.album_gain.to_bin).to eq("\x4c\x01")
    expect(frame.album_gain.adjustment).to eq(0.1)
  end
  
  it "should have a maximum positive gain adjustment of 25.5 dB" do
    frame = ID3V24::RGADFrame.default(0)
    # need to do it this way so I can directly set the raw adjustment
    gain = frame.album_gain
    gain.raw_adjustment = 255
    frame.album_gain = gain
    
    expect(frame.album_gain.raw_adjustment).to eq(255)
    expect(frame.album_gain.to_bin).to eq("\x4c\xff")
    expect(frame.album_gain.adjustment).to eq(25.5)
  end
  
  it "should have a minimum negative gain increment of -0.1 dB" do
    frame = ID3V24::RGADFrame.default(0)
    # need to do it this way so I can directly set the raw adjustment
    gain = frame.track_gain
    gain.raw_adjustment = -1
    frame.track_gain = gain
    
    expect(frame.track_gain.raw_adjustment).to eq(-1)
    expect(frame.track_gain.to_bin).to eq("\x2e\x01")
    expect(frame.track_gain.adjustment).to eq(-0.1)
  end
  
  it "should have a maximum negative gain adjustment of -25.5 dB" do
    frame = ID3V24::RGADFrame.default(0)
    # need to do it this way so I can directly set the raw adjustment
    gain = frame.track_gain
    gain.raw_adjustment = -255
    frame.track_gain = gain
    
    expect(frame.track_gain.raw_adjustment).to eq(-255)
    expect(frame.track_gain.to_bin).to eq("\x2e\xff")
    expect(frame.track_gain.adjustment).to eq(-25.5)
  end
  
  it "should be able to set the track adjustment's origin as 'preset'" do
    frame = ID3V24::RGADFrame.default(1.3)
    gain = frame.track_gain
    gain.origin_code = ID3V24::RGADAdjustment::ORIGIN_PRESET
    frame.track_gain = gain
    
    expect(frame.track_gain.to_bin).to eq("\x24\x0d")
    expect(frame.track_gain.origin).to eq('preset')
  end
  
  it "should be able to set the album adjustment's origin as 'user'" do
    frame = ID3V24::RGADFrame.default(1.3)
    gain = frame.album_gain
    gain.origin_code = ID3V24::RGADAdjustment::ORIGIN_USER
    frame.album_gain = gain
    
    expect(frame.album_gain.to_bin).to eq("\x48\x0d")
    expect(frame.album_gain.origin).to eq('user')
  end
  
  it "should be able to set the track adjustment's type as 'album', while invalidating the frame" do
    frame = ID3V24::RGADFrame.default(1.3)
    gain = frame.track_gain
    gain.type_code = ID3V24::RGADAdjustment::TYPE_AUDIOPHILE
    frame.track_gain = gain
    
    expect(frame.track_gain.valid?).to be true
    expect(frame.track_gain.to_bin).to eq("\x4c\x0d")
    expect(frame.track_gain.type).to eq('album')
    expect(frame.valid?).to be false
  end
  
  it "should be able to set the album adjustment's type as 'track', while invalidating the frame" do
    frame = ID3V24::RGADFrame.default(1.3)
    gain = frame.album_gain
    gain.type_code = ID3V24::RGADAdjustment::TYPE_RADIO
    frame.album_gain = gain
    
    expect(frame.album_gain.valid?).to be true
    expect(frame.album_gain.to_bin).to eq("\x2c\x0d")
    expect(frame.album_gain.type).to eq('track')
    expect(frame.valid?).to be false
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
    expect(@saved_frame.class).to eq(ID3V24::RGADFrame)
  end
  
  it "should be valid" do
    expect(@saved_frame.valid?).to be true
  end
  
  it "should have a peak amplitude of 0.98475" do
    expect(@saved_frame.peak).to be_within(0.00001).of(0.98475)
  end
  
  it "should have a valid track gain adjustment" do
    expect(@saved_frame.track_gain.valid?).to be true
  end
  
  it "should have a track gain adjustment type of 'track'" do
    expect(@saved_frame.track_gain.type).to eq('track')
  end
  
  it "should have a track gain adjustment origin of 'user'" do
    expect(@saved_frame.track_gain.origin).to eq('user')
  end
  
  it "should have a track gain adjustment value of -2 dB" do
    expect(@saved_frame.track_gain.adjustment).to eq(-2.0)
  end
  
  it "should have a track gain raw adjustment value of -20" do
    expect(@saved_frame.track_gain.raw_adjustment).to eq(-20)
  end
  
  it "should have a valid album gain adjustment" do
    expect(@saved_frame.album_gain.valid?).to be true
  end
  
  it "should have an album gain adjustment type of 'album'" do
    expect(@saved_frame.album_gain.type).to eq('album')
  end
  
  it "should have an album gain adjustment origin of 'automatic'" do
    expect(@saved_frame.album_gain.origin).to eq('automatic')
  end
  
  it "should have an album gain adjustment value of -2 dB" do
    expect(@saved_frame.album_gain.adjustment).to eq(2.0)
  end
  
  it "should have an album gain raw adjustment value of -20" do
    expect(@saved_frame.album_gain.raw_adjustment).to eq(20)
  end
end
