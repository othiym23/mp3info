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
    expect(@sample_header.valid?).to eq(true)
  end
  
  it "should detect that sample header comes from an MPEG version 1.0 frame" do
    expect(@sample_header.version).to eq(1.0)
  end
  
  it "should detect that sample header comes from an MPEG layer 3 frame" do
    expect(@sample_header.layer).to eq(3)
  end
  
  it "should detect that sample header comes from an unpadded frame" do
    expect(@sample_header.padded_stream?).to be false
  end
  
  it "should detect that sample header comes from a frame with no error protection" do
    expect(@sample_header.error_protected?).to be false
  end
  
  it "should detect that sample header comes from a stream with a frame size of 417" do
    expect(@sample_header.frame_size).to eq(417)
  end
  
  it "should detect that sample header comes from a frame with an MPEG CBR bitrate of 128" do
    expect(@sample_header.bitrate).to eq(128)
  end
  
  it "should detect that sample header comes from a frame with a sample frequency of 44.1KHz" do
    expect(@sample_header.sample_rate).to eq(44_100)
  end
  
  it "should detect that sample header comes from a frame with no emphasis" do
    expect(@sample_header.emphasis).to eq('none')
  end
  
  it "should detect that sample header comes from a frame with a channel mode of 'Joint stereo'" do
    expect(@sample_header.mode).to eq(MPEGHeader::MODE_JOINT_STEREO)
  end
  
  it "should detect that sample header comes from a frame with intensity stereo turned off" do
    expect((@sample_header.mode_extension & MPEGHeader::MODE_EXTENSION_INTENSITY)).to eq(0)
  end
  
  it "should detect that sample header comes from a frame with m/s stereo turned on" do
    expect((@sample_header.mode_extension & MPEGHeader::MODE_EXTENSION_M_S_STEREO)).to eq(MPEGHeader::MODE_EXTENSION_M_S_STEREO)
  end
  
  it "should detect that sample header comes from a frame with the private bit clear" do
    expect(@sample_header.private_stream?).to be false
  end
  
  it "should detect that sample header comes from a frame declared to not be copyrighted" do
    expect(@sample_header.copyrighted_stream?).to be false
  end
  
  it "should detect that sample header comes from a frame declared to be original content" do
    expect(@sample_header.original_stream?).to be true
  end

  it "should calculate correct frame duration for MPEG1 Layer III" do
    # 1152 samples / 44100 Hz
    expect(@sample_header.frame_duration).to be_within(0.00001).of(1152.0 / 44100.0)
  end
end

describe MPEGHeader, "frame duration for MPEG2 Layer III" do
  before do
    # MPEG2, Layer III, 32kbps, 22050Hz, stereo
    header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync
        1, 0,                             # version: 2.0
        0, 1,                             # layer: 3
        1,                                # no CRC
        0, 1, 0, 1,                       # bitrate: 40kbps
        0, 0,                             # sample rate: 22050Hz
        0,                                # no padding
        0,                                # private: not set
        0, 0,                             # mode: stereo
        0, 0,                             # mode extension
        0,                                # not copyrighted
        1,                                # original
        0, 0 ]                            # no emphasis
    @header = MPEGHeader.new(header_array.to_binary_string)
  end

  it "should use 576 samples per frame for MPEG2 Layer III" do
    expect(@header.samples_per_frame).to eq(576)
  end

  it "should calculate frame duration as 576/sample_rate, not 1152/sample_rate" do
    expect(@header.frame_duration).to be_within(0.00001).of(576.0 / 22050.0)
  end
end
