$:.unshift("lib/")

require 'mp3info/mpeg_header'

describe MPEGHeader, "parsing a variety of invalid MPEG headers" do
  it "should detect that '\\x00\\x00\\x00\\x00' is an invalid MPEG header" do
    header = MPEGHeader.new("\x00\x00\x00\x00")
    expect(header.valid?).to eq(false)
  end
  
  it "should detect that '\\xff\\xff\\xff\\xff' is an invalid MPEG header" do
    header = MPEGHeader.new("\xff\xff\xff\xff")
    expect(header.valid?).to eq(false)
  end
  
  it "should detect that provided header has an invalid sync stream in validity check" do
    invalid_header_array =
      [ 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,  # sync bitstream: changed (but how?)*
        1, 1,                             # version: 1.0
        0, 0,                             # layer: 0*
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
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should detect that provided header has an invalid layer number in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 0,                             # layer: 0*
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
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should raise an error when trying to access the layer in provided header" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 0,                             # layer: 0*
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
    expect { MPEGHeader.new(invalid_header_array.to_binary_string).layer }.to raise_error(InvalidMPEGHeader)
  end
  
  it "should detect that provided header has an invalid version code in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        0, 1,                             # version: ?*
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
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should raise an error when trying to access the layer in provided header" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        0, 1,                             # version: ?*
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
    expect { MPEGHeader.new(invalid_header_array.to_binary_string).version }.to raise_error(InvalidMPEGHeader)
  end
  
  it "should detect that provided header has an invalid bitrate code (0x0f) in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 1, 1, 1,                       # CBR bitrate: reserved value*
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should raise an error when trying to access the bitrate (for code 0x0f) in provided header" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 1, 1, 1,                       # CBR bitrate: reserved value*
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    expect { MPEGHeader.new(invalid_header_array.to_binary_string).bitrate }.to raise_error(InvalidMPEGHeader)
  end
  
  it "should raise an error when trying to access emphasis for invalid emphasis code in provided code" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 1, 0, 1,                       # CBR bitrate: 256
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        1, 0                              # emphasis: reserved value*
        ]
    expect { MPEGHeader.new(invalid_header_array.to_binary_string).emphasis }.to raise_error(InvalidMPEGHeader)
  end
  
  it "should detect that provided header has an invalid sample frequency (3) in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 0, 0, 1,                       # CBR bitrate: 128kbps
        1, 1,                             # sample frequency: ?*
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should detect that provided header can't have a bitrate of 32 and a mode other than mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        0, 0, 0, 1,                       # CBR bitrate: 32kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).version).to eq(1.0)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).layer).to eq(2)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).bitrate).to eq(32)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).mode).to eq(MPEGHeader::MODE_JOINT_STEREO)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should detect that provided header can't have a bitrate of 48 and a mode other than mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        0, 0, 1, 0,                       # CBR bitrate: 48kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).version).to eq(1.0)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).layer).to eq(2)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).bitrate).to eq(48)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).mode).to eq(MPEGHeader::MODE_JOINT_STEREO)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should detect that provided header can't have a bitrate of 56 and a mode other than mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        0, 0, 1, 1,                       # CBR bitrate: 56kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).version).to eq(1.0)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).layer).to eq(2)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).bitrate).to eq(56)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).mode).to eq(MPEGHeader::MODE_JOINT_STEREO)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should detect that provided header can't have a bitrate of 80 and a mode other than mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        0, 1, 0, 1,                       # CBR bitrate: 80kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).version).to eq(1.0)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).layer).to eq(2)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).bitrate).to eq(80)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).mode).to eq(MPEGHeader::MODE_JOINT_STEREO)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should detect that provided header can't have a bitrate of 224 and be mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        1, 0, 1, 1,                       # CBR bitrate: 224kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        1, 1,                             # channel mode: mono*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        0,                                # original: no
        0, 0                              # emphasis: none
        ]
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).version).to eq(1.0)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).layer).to eq(2)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).bitrate).to eq(224)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).mode).to eq(MPEGHeader::MODE_MONO)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should detect that provided header can't have a bitrate of 256 and be mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        1, 1, 0, 0,                       # CBR bitrate: 256kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        1, 1,                             # channel mode: mono*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        0,                                # original: no
        0, 0                              # emphasis: none
        ]
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).version).to eq(1.0)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).layer).to eq(2)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).bitrate).to eq(256)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).mode).to eq(MPEGHeader::MODE_MONO)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should detect that provided header can't have a bitrate of 320 and be mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        1, 1, 0, 1,                       # CBR bitrate: 320kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        1, 1,                             # channel mode: mono*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        0,                                # original: no
        0, 0                              # emphasis: none
        ]
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).version).to eq(1.0)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).layer).to eq(2)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).bitrate).to eq(320)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).mode).to eq(MPEGHeader::MODE_MONO)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should detect that provided header can't have a bitrate of 384 and be mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        1, 1, 1, 0,                       # CBR bitrate: 384kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        1, 1,                             # channel mode: mono*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        0,                                # original: no
        0, 0                              # emphasis: none
        ]
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).version).to eq(1.0)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).layer).to eq(2)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).bitrate).to eq(384)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).mode).to eq(MPEGHeader::MODE_MONO)
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
  
  it "should detect that an MPEG 1.0 Layer III file can't have an emphasis of type RESERVED" do
    invalid_header_array =
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
        1, 0                              # emphasis: reserved
        ]
    expect(MPEGHeader.new(invalid_header_array.to_binary_string).valid?).to eq(false)
  end
end
