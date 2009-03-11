# encoding: binary
$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::XRVFrame, "when creating a new XRV (ID3v2.2 replay gain) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @gain = 4.3
    @frame = ID3V24::Frame.create_frame("XRV", @gain)
  end
  
  it "should be the correct class" do
    @frame.class.should == ID3V24::XRVFrame
  end
  
  it "should default to adjusting track-level replay gain" do
    @frame.identifier.should == 'track'
  end
  
  it "should come with a single adjustment" do
    @frame.adjustments.size.should == 1
  end
  
  it "should preserve the gain adjustment set within a tolerance of the epsilon for the adjustment (0.001953125)" do
    @frame.adjustments.first.adjustment.should be_close(@gain, 0.001953125)
  end
  
  it "should correctly calculate the raw adjustment value based on the dB value passed to the default generator" do
    @frame.adjustments.first.raw_adjustment.should == 2201
  end
  
  it "should have a peak gain adjustment scale 0 bits wide" do
    @frame.adjustments.first.peak_gain_bit_width == 0
  end
  
  it "should have a peak gain adjustment of 0" do
    @frame.adjustments.first.peak_gain == 0
  end
  
  it "should correctly encode itself to binary" do
    @frame.to_s.should == "track\x00\x01\x08\x99\x00"
  end
end
