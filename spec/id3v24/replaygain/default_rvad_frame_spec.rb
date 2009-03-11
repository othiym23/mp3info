# encoding: binary
$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::RVADFrame, "when creating a new RVAD (replay gain) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @gain = 1.33
    tag = { "RVAD" => ID3V24::Frame.create_frame("RVAD", @gain) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['RVAD']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should reconstitute itself as the correct class" do
    @saved_frame.class.should == ID3V24::RVADFrame
  end
  
  it "should have a volume bit width of 16 by default" do
    @saved_frame.bit_width.should == 16
  end
  
  it "should have adjustments made to the right channel by default" do
    @saved_frame.channel_adjusted?(ID3V24::RVADFrame::FRONT_RIGHT).should be_true
  end
  
  it "should preserve the gain adjustment of the right channel within the epsilon at 16 bits' width (0.001953125)" do
    @saved_frame.right_gain.should be_close(@gain, 0.001953125)
  end
  
  it "should have peak value on the right channel of 0" do
    @saved_frame.right_peak.should == 0
  end
  
  it "should have adjustments made to the left channel by default" do
    @saved_frame.channel_adjusted?(ID3V24::RVADFrame::FRONT_LEFT).should be_true
  end
  
  it "should preserve the gain adjustment of the left channel within the epsilon at 16 bits' width (0.001953125)" do
    @saved_frame.left_gain.should be_close(@gain, 0.001953125)
  end
  
  it "should have peak value on the left channel of 0" do
    @saved_frame.left_peak.should == 0
  end
  
  it "should correctly encode itself to binary" do
    @saved_frame.to_s.should == "\x03\x10\x2a\x5c\x2a\x5c\x00\x00\x00\x00"
  end
  
  it "should correctly state that the rear right channel is not adjusted" do
    @saved_frame.channel_adjusted?(ID3V24::RVADFrame::REAR_RIGHT).should be_false
  end
  
  it "should correctly state that the rear left channel is not adjusted" do
    @saved_frame.channel_adjusted?(ID3V24::RVADFrame::REAR_LEFT).should be_false
  end
  
  it "should correctly state that the center channel is not adjusted" do
    @saved_frame.channel_adjusted?(ID3V24::RVADFrame::CENTER).should be_false
  end
  
  it "should correctly state that the subwoofer channel is not adjusted" do
    @saved_frame.channel_adjusted?(ID3V24::RVADFrame::SUBWOOFER).should be_false
  end
end
