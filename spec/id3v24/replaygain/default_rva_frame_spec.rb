# encoding: binary
$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::RVAFrame, "when creating a new RVAD (replay gain) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @gain = 1.33
    @frame = ID3V24::Frame.create_frame("RVA", @gain)
  end
  
  it "should be the correct class" do
    @frame.class.should == ID3V24::RVAFrame
  end
  
  it "should have a volume bit width of 16 by default" do
    @frame.bit_width.should == 16
  end
  
  it "should preserve the gain adjustment of the right channel within the epsilon at 16 bits' width (0.001953125)" do
    @frame.right_gain.should be_close(@gain, 0.001953125)
  end
  
  it "should have peak value on the right channel of 0" do
    @frame.right_peak.should == 0
  end
  
  it "should preserve the gain adjustment of the left channel within the epsilon at 16 bits' width (0.001953125)" do
    @frame.left_gain.should be_close(@gain, 0.001953125)
  end
  
  it "should have peak value on the left channel of 0" do
    @frame.left_peak.should == 0
  end
  
  it "should correctly encode itself to binary" do
    @frame.to_s.should == "\x03\x10\x2a\x5c\x2a\x5c\x00\x00\x00\x00"
  end
end
