# encoding: binary
$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::RVAFrame, "when strictly interpreting the ID3v2.3 specification" do
  it "should have a minimum positive gain increment of 0.000132535146647037 dB at a 16 bit width" do
    frame = ID3V24::RVAFrame.default(0)
    frame.set_raw(ID3V24::RVAFrame::RIGHT, 1)
    frame.value.should == "\x03\x10\x00\x01\x00\x00\x00\x00\x00\x00"
    frame.get_db(ID3V24::RVAFrame::RIGHT).should be_close(0.000132535146647037, 0.0000000000000001)
  end
  
  it "should have a minimum negative gain increment of -0.000132537168988313 dB" do
    frame = ID3V24::RVAFrame.default(0)
    frame.set_raw(ID3V24::RVAFrame::RIGHT, 1)
    frame.set_channel_sign!(ID3V24::RVAFrame::RIGHT, -1)
    frame.value.should == "\x02\x10\x00\x01\x00\x00\x00\x00\x00\x00"
    frame.get_db(ID3V24::RVAFrame::RIGHT).should be_close(-0.000132537168988313, 0.000000000000000001)
  end
  
  it "should find 2 adjustments in a raw dump of an example frame, with their values" do
    frame = ID3V24::RVAFrame.default(0)
    frame.set_db(ID3V24::RVAFrame::RIGHT, 2.0)
    frame.set_db(ID3V24::RVAFrame::LEFT, -2.0)
    frame.adjustments.size.should == 2
    
    first_adjustment = frame.adjustments[0]
    first_adjustment.channel_type.should == 'Front right'
    first_adjustment.adjustment.should be_close(2.0, 0.00001)
    first_adjustment.peak_gain_bit_width.should == 16
    first_adjustment.peak_gain.should == 0
    
    second_adjustment = frame.adjustments[1]
    second_adjustment.channel_type.should == 'Front left'
    second_adjustment.adjustment.should be_close(-2.0, 0.0001)
    second_adjustment.peak_gain_bit_width.should == 16
    second_adjustment.peak_gain.should == 0
  end
  
  it "should correctly handle peak gain bit widths that are not modulo 8 bits wide (e.g. 5 bits)" do
    frame = ID3V24::RVAFrame.from_s("\x00\x05\x00\x00\x00\x00")
    frame.adjustments.first.peak_gain_bit_width.should == 5
    frame.adjustments.first.peak_gain.should == 0
    
    frame = ID3V24::RVAFrame.from_s("\x00\x05\x00\x00\x15\x00")
    frame.adjustments.first.peak_gain_bit_width.should == 5
    frame.adjustments.first.peak_gain.should == 21
    
    frame = ID3V24::RVAFrame.from_s("\x00\x05\x00\x00\x0a\x00")
    frame.adjustments.first.peak_gain_bit_width.should == 5
    frame.adjustments.first.peak_gain.should == 10
    
    frame = ID3V24::RVAFrame.from_s("\x00\x05\x00\x00\x1f\x00")
    frame.adjustments.first.peak_gain_bit_width.should == 5
    frame.adjustments.first.peak_gain.should == 31
  end
  
  it "should correctly handle peak gain bit widths that are not modulo 8 bits wide (e.g. 22 bits)" do
    frame = ID3V24::RVAFrame.from_s("\x00\x16\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00")
    frame.adjustments.first.peak_gain_bit_width.should == 22
    frame.adjustments.first.peak_gain.should == 0
    
    frame = ID3V24::RVAFrame.from_s("\x00\x16\x00\x00\x00\x00\x00\x00\x15\x55\x55\x00\x00\x00")
    frame.adjustments.first.peak_gain_bit_width.should == 22
    frame.adjustments.first.peak_gain.should == 1_398_101
    
    frame = ID3V24::RVAFrame.from_s("\x00\x16\x00\x00\x00\x00\x00\x00\x2a\xaa\xaa\x00\x00\x00")
    frame.adjustments.first.peak_gain_bit_width.should == 22
    frame.adjustments.first.peak_gain.should == 2_796_202
    
    frame = ID3V24::RVAFrame.from_s("\x00\x16\x00\x00\x00\x00\x00\x00\x3f\xff\xff\x00\x00\x00")
    frame.adjustments.first.peak_gain_bit_width.should == 22
    frame.adjustments.first.peak_gain.should == 4_194_303
  end
  
  it "should allow setting the right channel gain directly" do
    frame = ID3V24::RVAFrame.default(-0.8)
    frame.right_gain = 1.1
    frame.right_gain.should be_close(1.1, 0.0001)
    frame.left_gain.should be_close(-0.8, 0.0001)
  end
  
  it "should allow setting the left channel gain directly" do
    frame = ID3V24::RVAFrame.default(-0.8)
    frame.left_gain = 1.1
    frame.right_gain.should be_close(-0.8, 0.0001)
    frame.left_gain.should be_close(1.1, 0.0001)
  end
  
  it "should allow setting the right channel peak directly" do
    frame = ID3V24::RVAFrame.default(-0.8)
    frame.right_peak = 6_553
    frame.right_peak.should == 6_553
    frame.left_peak.should == 0
  end
  
  it "should allow setting the left channel peak directly" do
    frame = ID3V24::RVAFrame.default(-0.8)
    frame.left_peak = 6_553
    frame.right_peak.should == 0
    frame.left_peak.should == 6_553
  end
end

describe ID3V24::RVAFrame, "when parsing a simple RVAD (ID3v2.3 volume adjustment) frame containing one adjustment of -2dB" do
  include Mp3InfoHelper
  
  before :all do
    @rvad = "\x02\x10\x34\xa7\x00\x01\x00\x00\x00\x00"
    @frame = ID3V24::Frame.create_frame_from_string("RVA", @rvad)
  end
  
  it "should be reconstituted as the correct class" do
    @frame.class.should == ID3V24::RVAFrame
  end
  
  it "should have a channel type of 'Front right'" do
    @frame.adjustments.first.channel_type.should == 'Front right'
  end
  
  it "should have a channel adjustment value of -2 dB" do
    @frame.adjustments.first.adjustment.should be_close(-2.0, 0.00002)
  end
  
  it "should have a channel raw adjustment value of -1024" do
    @frame.adjustments.first.raw_adjustment.should == -1024
  end
  
  it "should have a peak gain adjustment of 0" do
    @frame.adjustments.first.peak_gain.should == 0
  end
end

describe ID3V24::RVAFrame, "when parsing a simple RVAD (ID3v2.3 replaygain) frame containing one adjustment of 6dB and a peak gain adjustment" do
  include Mp3InfoHelper
  
  before :all do
    @rvad = "\x03\x10\x95\xbc\x00\x01\x19\x99\x00\x00"
    @frame = ID3V24::Frame.create_frame_from_string("RVA", @rvad)
  end
  
  it "should be reconstituted as the correct class" do
    @frame.class.should == ID3V24::RVAFrame
  end
  
  it "should have a channel type of 'Front right'" do
    @frame.adjustments.first.channel_type.should == 'Front right'
  end
  
  it "should have a channel adjustment value of 16 dB" do
    @frame.adjustments.first.adjustment.should == 4.0
  end
  
  it "should have a channel raw adjustment value of 8,192" do
    @frame.adjustments.first.raw_adjustment.should == 2_048
  end
  
  it "should have a peak gain adjustment of 6,553" do
    @frame.adjustments.first.peak_gain.should == 6_553
  end
  
  it "should have a peak gain width of 16" do
    @frame.adjustments.first.peak_gain_bit_width.should == 16
  end
end
