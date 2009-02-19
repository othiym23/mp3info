$:.unshift("lib/")

require 'mp3info/mpeg_header'

describe MPEGHeader, "parsing a valid sample MPEG header" do
  before do
    sample_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 0, 0, 1,                       # CBR bitrate: 128kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    @sample_header = MPEGHeader.new(sample_header_array.to_binary_string)
  end
  
  it "should detect that sample header '\\xff\\xfb\\x90\\x64' is a valid MPEG header" do
    @sample_header.valid?.should == true
  end
  
  it "should detect that sample header comes from an MPEG version 1.0 frame" do
    @sample_header.version.should == 1.0
  end
  
  it "should detect that sample header comes from an MPEG layer 3 frame" do
    @sample_header.layer.should == 3
  end
  
  it "should detect that sample header comes from an unpadded frame" do
    @sample_header.padded_stream?.should be_false
  end
  
  it "should detect that sample header comes from a frame with no error protection" do
    @sample_header.error_protected?.should be_false
  end
  
  it "should detect that sample header comes from a stream with a frame size of 417" do
    @sample_header.frame_size.should == 417
  end
  
  it "should detect that sample header comes from a frame with an MPEG CBR bitrate of 128" do
    @sample_header.bitrate.should == 128
  end
  
  it "should detect that sample header comes from a frame with a sample frequency of 44.1KHz" do
    @sample_header.sample_rate.should == 44_100
  end
  
  it "should detect that sample header comes from a frame with no emphasis" do
    @sample_header.emphasis.should == 'none'
  end
  
  it "should detect that sample header comes from a frame with a channel mode of 'Joint stereo'" do
    @sample_header.mode.should == MPEGHeader::MODE_JOINT_STEREO
  end
  
  it "should detect that sample header comes from a frame with intensity stereo turned off" do
    (@sample_header.mode_extension & MPEGHeader::MODE_EXTENSION_INTENSITY).should == 0
  end
  
  it "should detect that sample header comes from a frame with m/s stereo turned on" do
    (@sample_header.mode_extension & MPEGHeader::MODE_EXTENSION_M_S_STEREO).should == MPEGHeader::MODE_EXTENSION_M_S_STEREO
  end
  
  it "should detect that sample header comes from a frame with the private bit clear" do
    @sample_header.private_stream?.should be_false
  end
  
  it "should detect that sample header comes from a frame declared to not be copyrighted" do
    @sample_header.copyrighted_stream?.should be_false
  end
  
  it "should detect that sample header comes from a frame declared to be original content" do
    @sample_header.original_stream?.should be_true
  end
end
