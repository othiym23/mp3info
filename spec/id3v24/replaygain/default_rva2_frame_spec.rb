# encoding: binary
$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::RVA2Frame, "when creating a new RVA2 (replay gain) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    # Base64 encode the data because for this test I want to test the defaults, not binary storage
    @gain = 4.3
    tag = { "RVA2" => ID3V24::Frame.create_frame("RVA2", @gain) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['RVA2']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should reconstitute itself as the correct class" do
    @saved_frame.class.should == ID3V24::RVA2Frame
  end
  
  it "should default to adjusting track-level replay gain" do
    @saved_frame.identifier.should == 'track'
  end
  
  it "should come with a single adjustment" do
    @saved_frame.adjustments.size.should == 1
  end
  
  it "should preserve the gain adjustment set within a tolerance of the epsilon for the adjustment (0.001953125)" do
    @saved_frame.adjustments.first.adjustment.should be_close(@gain, 0.001953125)
  end
  
  it "should correctly calculate the raw adjustment value based on the dB value passed to the default generator" do
    @saved_frame.adjustments.first.raw_adjustment.should == 2201
  end
  
  it "should have a peak gain adjustment scale 0 bits wide" do
    @saved_frame.adjustments.first.peak_gain_bit_width == 0
  end
  
  it "should have a peak gain adjustment of 0" do
    @saved_frame.adjustments.first.peak_gain == 0
  end
  
  it "should correctly encode itself to binary" do
    @saved_frame.to_s.should == "track\x00\x01\x08\x99\x00"
  end
end
