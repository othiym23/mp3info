# encoding: binary

describe ID3V24::XRVAFrame, "when strictly interpreting the ID3v2.4 specification" do
  it "should have a minimum positive gain increment of 0.001953125 dB" do
    frame = ID3V24::XRVAFrame.default(0)
    frame.adjustments.first.raw_adjustment = 1
    expect(frame.adjustments.first.adjustment).to eq(0.001953125)
    expect(frame.adjustments.first.to_bin).to eq("\x01\x00\x01\x00")
  end
  
  it "should have a minimum negative gain increment of -0.001953125 dB" do
    frame = ID3V24::XRVAFrame.default(0)
    frame.adjustments.first.raw_adjustment = -1
    expect(frame.adjustments.first.adjustment).to eq(-0.001953125)
    # TODO this is not at all synchsafe, but apparently we don't care?
    expect(frame.adjustments.first.to_bin).to eq("\x01\xff\xff\x00")
  end
  
  it "should return a parse error if there are some extra bytes in the raw data" do
    expect { ID3V24::XRVAFrame.from_s("test\x00\x01\x00\x00\x00\x00") }.to raise_error(ID3V24::RVA2ParseError)
    expect { ID3V24::XRVAFrame.from_s("test\x00\x01\x00\x00\x00\x00\x00") }.to raise_error(ID3V24::RVA2ParseError)
    expect { ID3V24::XRVAFrame.from_s("test\x00\x01\x00\x00\x00\x00\x00\x00") }.to raise_error(ID3V24::RVA2ParseError)
  end
  
  it "should find 3 adjustments in a raw dump of an example frame, with their values" do
    frame = ID3V24::XRVAFrame.from_s("test\x00\x08\x04\x00\x00\x06\xfc\x00\x10\x80\x00\x07\x02\x00\x08\x80")
    expect(frame.adjustments.size).to eq(3)
    
    first_adjustment = frame.adjustments[0]
    expect(first_adjustment.channel_type).to eq('Subwoofer')
    expect(first_adjustment.adjustment).to eq(2.0)
    expect(first_adjustment.peak_gain_bit_width).to eq(0)
    expect(first_adjustment.peak_gain).to eq(0)
    
    second_adjustment = frame.adjustments[1]
    expect(second_adjustment.channel_type).to eq('Front centre')
    expect(second_adjustment.adjustment).to eq(-2.0)
    expect(second_adjustment.peak_gain_bit_width).to eq(16)
    expect(second_adjustment.peak_gain).to eq(32_768)
    
    third_adjustment = frame.adjustments[2]
    expect(third_adjustment.channel_type).to eq('Back centre')
    expect(third_adjustment.adjustment).to eq(1.0)
    expect(third_adjustment.peak_gain_bit_width).to eq(8)
    expect(third_adjustment.peak_gain).to eq(128)
  end
  
  it "should correctly handle peak gain bit widths that are not modulo 8 bits wide (e.g. 5 bits)" do
    frame = ID3V24::XRVAFrame.from_s("test\x00\x01\x00\x00\x05\x00")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(5)
    expect(frame.adjustments.first.peak_gain).to eq(0)
    
    frame = ID3V24::XRVAFrame.from_s("test\x00\x01\x00\x00\x05\x55")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(5)
    expect(frame.adjustments.first.peak_gain).to eq(21)
    
    frame = ID3V24::XRVAFrame.from_s("test\x00\x01\x00\x00\x05\xaa")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(5)
    expect(frame.adjustments.first.peak_gain).to eq(10)
    
    frame = ID3V24::XRVAFrame.from_s("test\x00\x01\x00\x00\x05\xff")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(5)
    expect(frame.adjustments.first.peak_gain).to eq(31)
  end
  
  it "should correctly handle peak gain bit widths that are not modulo 8 bits wide (e.g. 22 bits)" do
    frame = ID3V24::XRVAFrame.from_s("test\x00\x01\x00\x00\x16\x00\x00\x00")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(22)
    expect(frame.adjustments.first.peak_gain).to eq(0)
    
    frame = ID3V24::XRVAFrame.from_s("test\x00\x01\x00\x00\x16\x55\x55\x55")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(22)
    expect(frame.adjustments.first.peak_gain).to eq(1_398_101)
    
    frame = ID3V24::XRVAFrame.from_s("test\x00\x01\x00\x00\x16\xaa\xaa\xaa")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(22)
    expect(frame.adjustments.first.peak_gain).to eq(2_796_202)
    
    frame = ID3V24::XRVAFrame.from_s("test\x00\x01\x00\x00\x16\xff\xff\xff")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(22)
    expect(frame.adjustments.first.peak_gain).to eq(4_194_303)
  end
end

describe ID3V24::XRVAFrame, "when parsing a simple XRVA (ID3v2.3 replaygain) frame containing one adjustment of -2dB" do
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @rva2 = "track\x00\x01\xFC\x00\x00"
    tag = { "XRVA" => ID3V24::Frame.create_frame_from_string("XRVA", @rva2) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['XRVA']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should be reconstituted as the correct class" do
    expect(@saved_frame.class).to eq(ID3V24::XRVAFrame)
  end
  
  it "should have a replaygain ID of 'track'" do
    expect(@saved_frame.identifier).to eq("track")
  end
  
  it "should have a channel type of 'Master volume'" do
    expect(@saved_frame.adjustments.first.channel_type).to eq('Master volume')
  end
  
  it "should have a channel adjustment value of -2 dB" do
    expect(@saved_frame.adjustments.first.adjustment).to eq(-2.0)
  end
  
  it "should have a channel raw adjustment value of -1024" do
    expect(@saved_frame.adjustments.first.raw_adjustment).to eq(-1024)
  end
  
  it "should have a peak gain adjustment of 0" do
    expect(@saved_frame.adjustments.first.peak_gain).to eq(0)
  end
end

describe ID3V24::XRVAFrame, "when parsing a simple XRVA (ID3v2.3 replaygain) frame containing one adjustment of 16dB and a peak gain adjustment" do
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @rva2 = "track\x00\x01\x20\x00\x10\x19\x99"
    tag = { "XRVA" => ID3V24::Frame.create_frame_from_string("XRVA", @rva2) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['XRVA']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should be reconstituted as the correct class" do
    expect(@saved_frame.class).to eq(ID3V24::XRVAFrame)
  end
  
  it "should have a replaygain ID of 'track'" do
    expect(@saved_frame.identifier).to eq("track")
  end
  
  it "should have a channel type of 'Master volume'" do
    expect(@saved_frame.adjustments.first.channel_type).to eq('Master volume')
  end
  
  it "should have a channel adjustment value of 16 dB" do
    expect(@saved_frame.adjustments.first.adjustment).to eq(16.0)
  end
  
  it "should have a channel raw adjustment value of 8,192" do
    expect(@saved_frame.adjustments.first.raw_adjustment).to eq(8_192)
  end
  
  it "should have a peak gain adjustment of 6,553" do
    expect(@saved_frame.adjustments.first.peak_gain).to eq(6_553)
  end
  
  it "should have a peak gain width of 16" do
    expect(@saved_frame.adjustments.first.peak_gain_bit_width).to eq(16)
  end
end
