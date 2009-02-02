$:.unshift("lib/")

require 'mp3info/mpeg_header'

describe MPEGHeader, "with valid but unusual headers" do
  it "should detect CBR without errors for MPEG 2.5, layer 3 files" do
    valid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        0, 0,                             # version: 2.5
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 1, 0, 0,                       # CBR bitrate: 128kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(valid_header_array.to_binary_string).valid?.should == true
    MPEGHeader.new(valid_header_array.to_binary_string).bitrate.should == 128
  end
  
  it "should detect settings without errors for MPEG 2.5, layer 1 files" do
    valid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        0, 0,                             # version: 2.5
        1, 1,                             # layer: 1
        1,                                # protected: has no CRC
        1, 1, 0, 0,                       # CBR bitrate: 192kbps
        0, 0,                             # sample frequency: 11.025KHz
        1,                                # padding: padded
        1,                                # private: set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: bands 12 to 31
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).version.should == 2.5
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).valid?.should == true
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).bitrate.should == 192
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).sample_rate.should == 11_025
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).frame_size.should == 848
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_JOINT_STEREO
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).private_stream?.should == true
    # mode extension not supported by eyeD3
    (MPEGHeader.new(valid_header_array.to_binary_string).mode_extension & 
     MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31).should == MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31
  end
  
  it "should detect settings without errors for MPEG 2, layer 1 files" do
    valid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 0,                             # version: 2
        1, 1,                             # layer: 1
        1,                                # protected: has no CRC
        1, 1, 0, 0,                       # CBR bitrate: 192kbps
        0, 0,                             # sample frequency: 22.05KHz
        1,                                # padding: padded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: bands 12 to 31
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).version.should == 2
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).valid?.should == true
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).bitrate.should == 192
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).sample_rate.should == 22_050
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).frame_size.should == 432
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_JOINT_STEREO
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).private_stream?.should == false
    # mode extension not supported by eyeD3
    (MPEGHeader.new(valid_header_array.to_binary_string).mode_extension & 
     MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31).should == MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31
  end
  
  it "should detect settings without errors for MPEG 2.5, layer 2 files" do
    valid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        0, 0,                             # version: 2.5
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        1, 1, 0, 0,                       # CBR bitrate: 128kbps
        0, 0,                             # sample frequency: 11.025KHz
        1,                                # padding: padded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: bands 12 to 31
        1,                                # copyrighted: yes
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(valid_header_array.to_binary_string).version.should == 2.5
    MPEGHeader.new(valid_header_array.to_binary_string).layer.should == 2
    MPEGHeader.new(valid_header_array.to_binary_string).bitrate.should == 128
    MPEGHeader.new(valid_header_array.to_binary_string).sample_rate.should == 11_025
    MPEGHeader.new(valid_header_array.to_binary_string).frame_size.should == 1672
    MPEGHeader.new(valid_header_array.to_binary_string).copyrighted_stream?.should == true
    MPEGHeader.new(valid_header_array.to_binary_string).original_stream?.should == true
    MPEGHeader.new(valid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_JOINT_STEREO
    MPEGHeader.new(valid_header_array.to_binary_string).valid?.should == true
    MPEGHeader.new(valid_header_array.to_binary_string).private_stream?.should == false
    # mode extension not supported by eyeD3
    (MPEGHeader.new(valid_header_array.to_binary_string).mode_extension & 
     MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31).should == MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31
  end
  
  it "should handle a bitrate of 80 and a mode of mono" do
    valid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        0, 1, 0, 1,                       # CBR bitrate: 80kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        1, 1,                             # channel mode: mono
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        0,                                # original: no
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(valid_header_array.to_binary_string).version.should == 1.0
    MPEGHeader.new(valid_header_array.to_binary_string).layer.should == 2
    MPEGHeader.new(valid_header_array.to_binary_string).valid?.should == true
    MPEGHeader.new(valid_header_array.to_binary_string).bitrate.should == 80
    MPEGHeader.new(valid_header_array.to_binary_string).sample_rate.should == 44_100
    MPEGHeader.new(valid_header_array.to_binary_string).frame_size.should == 261
    MPEGHeader.new(valid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_MONO
    MPEGHeader.new(valid_header_array.to_binary_string).private_stream?.should == false
    # mode extension not supported by eyeD3
    (MPEGHeader.new(valid_header_array.to_binary_string).mode_extension & 
     MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31).should == MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31
  end
end
