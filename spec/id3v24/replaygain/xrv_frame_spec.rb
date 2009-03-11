# encoding: binary
$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::XRVFrame, "when strictly interpreting the ID3v2 specification" do
  it "should have a minimum positive gain increment of 0.001953125 dB" do
    frame = ID3V24::XRVFrame.default(0)
    frame.adjustments.first.raw_adjustment = 1
    frame.adjustments.first.adjustment.should == 0.001953125
    frame.adjustments.first.to_bin.should == "\x01\x00\x01\x00"
  end
  
  it "should have a minimum negative gain increment of -0.001953125 dB" do
    frame = ID3V24::XRVFrame.default(0)
    frame.adjustments.first.raw_adjustment = -1
    frame.adjustments.first.adjustment.should == -0.001953125
    # TODO this is not at all synchsafe, but apparently we don't care?
    frame.adjustments.first.to_bin.should == "\x01\xff\xff\x00"
  end
  
  it "should return a parse error if there are some extra bytes in the raw data" do
    lambda { ID3V24::XRVFrame.from_s("test\x00\x01\x00\x00\x00\x00") }.should raise_error(ID3V24::RVA2ParseError)
    lambda { ID3V24::XRVFrame.from_s("test\x00\x01\x00\x00\x00\x00\x00") }.should raise_error(ID3V24::RVA2ParseError)
    lambda { ID3V24::XRVFrame.from_s("test\x00\x01\x00\x00\x00\x00\x00\x00") }.should raise_error(ID3V24::RVA2ParseError)
  end
  
  it "should find 3 adjustments in a raw dump of an example frame, with their values" do
    frame = ID3V24::XRVFrame.from_s("test\x00\x08\x04\x00\x00\x06\xfc\x00\x10\x80\x00\x07\x02\x00\x08\x80")
    frame.adjustments.size.should == 3
    
    first_adjustment = frame.adjustments[0]
    first_adjustment.channel_type.should == 'Subwoofer'
    first_adjustment.adjustment.should == 2.0
    first_adjustment.peak_gain_bit_width.should == 0
    first_adjustment.peak_gain.should == 0
    
    second_adjustment = frame.adjustments[1]
    second_adjustment.channel_type.should == 'Front centre'
    second_adjustment.adjustment.should == -2.0
    second_adjustment.peak_gain_bit_width.should == 16
    second_adjustment.peak_gain.should == 32_768
    
    third_adjustment = frame.adjustments[2]
    third_adjustment.channel_type.should == 'Back centre'
    third_adjustment.adjustment.should == 1.0
    third_adjustment.peak_gain_bit_width.should == 8
    third_adjustment.peak_gain.should == 128
  end
  
  it "should correctly handle peak gain bit widths that are not modulo 8 bits wide (e.g. 5 bits)" do
    frame = ID3V24::XRVFrame.from_s("test\x00\x01\x00\x00\x05\x00")
    frame.adjustments.first.peak_gain_bit_width.should == 5
    frame.adjustments.first.peak_gain.should == 0
    
    frame = ID3V24::XRVFrame.from_s("test\x00\x01\x00\x00\x05\x55")
    frame.adjustments.first.peak_gain_bit_width.should == 5
    frame.adjustments.first.peak_gain.should == 21
    
    frame = ID3V24::XRVFrame.from_s("test\x00\x01\x00\x00\x05\xaa")
    frame.adjustments.first.peak_gain_bit_width.should == 5
    frame.adjustments.first.peak_gain.should == 10
    
    frame = ID3V24::XRVFrame.from_s("test\x00\x01\x00\x00\x05\xff")
    frame.adjustments.first.peak_gain_bit_width.should == 5
    frame.adjustments.first.peak_gain.should == 31
  end
  
  it "should correctly handle peak gain bit widths that are not modulo 8 bits wide (e.g. 22 bits)" do
    frame = ID3V24::XRVFrame.from_s("test\x00\x01\x00\x00\x16\x00\x00\x00")
    frame.adjustments.first.peak_gain_bit_width.should == 22
    frame.adjustments.first.peak_gain.should == 0
    
    frame = ID3V24::XRVFrame.from_s("test\x00\x01\x00\x00\x16\x55\x55\x55")
    frame.adjustments.first.peak_gain_bit_width.should == 22
    frame.adjustments.first.peak_gain.should == 1_398_101
    
    frame = ID3V24::XRVFrame.from_s("test\x00\x01\x00\x00\x16\xaa\xaa\xaa")
    frame.adjustments.first.peak_gain_bit_width.should == 22
    frame.adjustments.first.peak_gain.should == 2_796_202
    
    frame = ID3V24::XRVFrame.from_s("test\x00\x01\x00\x00\x16\xff\xff\xff")
    frame.adjustments.first.peak_gain_bit_width.should == 22
    frame.adjustments.first.peak_gain.should == 4_194_303
  end
end
