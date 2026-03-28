# encoding: binary

describe ID3V24::RVAFrame, "when strictly interpreting the ID3v2.3 specification" do
  it "should have a minimum positive gain increment of 0.000132535146647037 dB at a 16 bit width" do
    frame = ID3V24::RVAFrame.default(0)
    frame.set_raw(ID3V24::RVAFrame::RIGHT, 1)
    expect(frame.value).to eq("\x03\x10\x00\x01\x00\x00\x00\x00\x00\x00")
    expect(frame.get_db(ID3V24::RVAFrame::RIGHT)).to be_within(0.0000000000000001).of(0.000132535146647037)
  end

  it "should have a minimum negative gain increment of -0.000132537168988313 dB" do
    frame = ID3V24::RVAFrame.default(0)
    frame.set_raw(ID3V24::RVAFrame::RIGHT, 1)
    frame.set_channel_sign!(ID3V24::RVAFrame::RIGHT, -1)
    expect(frame.value).to eq("\x02\x10\x00\x01\x00\x00\x00\x00\x00\x00")
    expect(frame.get_db(ID3V24::RVAFrame::RIGHT)).to be_within(0.000000000000000001).of(-0.000132537168988313)
  end

  it "should find 2 adjustments in a raw dump of an example frame, with their values" do
    frame = ID3V24::RVAFrame.default(0)
    frame.set_db(ID3V24::RVAFrame::RIGHT, 2.0)
    frame.set_db(ID3V24::RVAFrame::LEFT, -2.0)
    expect(frame.adjustments.size).to eq(2)

    first_adjustment = frame.adjustments[0]
    expect(first_adjustment.channel_type).to eq("Front right")
    expect(first_adjustment.adjustment).to be_within(0.00001).of(2.0)
    expect(first_adjustment.peak_gain_bit_width).to eq(16)
    expect(first_adjustment.peak_gain).to eq(0)

    second_adjustment = frame.adjustments[1]
    expect(second_adjustment.channel_type).to eq("Front left")
    expect(second_adjustment.adjustment).to be_within(0.0001).of(-2.0)
    expect(second_adjustment.peak_gain_bit_width).to eq(16)
    expect(second_adjustment.peak_gain).to eq(0)
  end

  it "should correctly handle peak gain bit widths that are not modulo 8 bits wide (e.g. 5 bits)" do
    frame = ID3V24::RVAFrame.from_s("\x00\x05\x00\x00\x00\x00")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(5)
    expect(frame.adjustments.first.peak_gain).to eq(0)

    frame = ID3V24::RVAFrame.from_s("\x00\x05\x00\x00\x15\x00")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(5)
    expect(frame.adjustments.first.peak_gain).to eq(21)

    frame = ID3V24::RVAFrame.from_s("\x00\x05\x00\x00\x0a\x00")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(5)
    expect(frame.adjustments.first.peak_gain).to eq(10)

    frame = ID3V24::RVAFrame.from_s("\x00\x05\x00\x00\x1f\x00")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(5)
    expect(frame.adjustments.first.peak_gain).to eq(31)
  end

  it "should correctly handle peak gain bit widths that are not modulo 8 bits wide (e.g. 22 bits)" do
    frame = ID3V24::RVAFrame.from_s("\x00\x16\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(22)
    expect(frame.adjustments.first.peak_gain).to eq(0)

    frame = ID3V24::RVAFrame.from_s("\x00\x16\x00\x00\x00\x00\x00\x00\x15\x55\x55\x00\x00\x00")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(22)
    expect(frame.adjustments.first.peak_gain).to eq(1_398_101)

    frame = ID3V24::RVAFrame.from_s("\x00\x16\x00\x00\x00\x00\x00\x00\x2a\xaa\xaa\x00\x00\x00")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(22)
    expect(frame.adjustments.first.peak_gain).to eq(2_796_202)

    frame = ID3V24::RVAFrame.from_s("\x00\x16\x00\x00\x00\x00\x00\x00\x3f\xff\xff\x00\x00\x00")
    expect(frame.adjustments.first.peak_gain_bit_width).to eq(22)
    expect(frame.adjustments.first.peak_gain).to eq(4_194_303)
  end

  it "should allow setting the right channel gain directly" do
    frame = ID3V24::RVAFrame.default(-0.8)
    frame.right_gain = 1.1
    expect(frame.right_gain).to be_within(0.0001).of(1.1)
    expect(frame.left_gain).to be_within(0.0001).of(-0.8)
  end

  it "should allow setting the left channel gain directly" do
    frame = ID3V24::RVAFrame.default(-0.8)
    frame.left_gain = 1.1
    expect(frame.right_gain).to be_within(0.0001).of(-0.8)
    expect(frame.left_gain).to be_within(0.0001).of(1.1)
  end

  it "should allow setting the right channel peak directly" do
    frame = ID3V24::RVAFrame.default(-0.8)
    frame.right_peak = 6_553
    expect(frame.right_peak).to eq(6_553)
    expect(frame.left_peak).to eq(0)
  end

  it "should allow setting the left channel peak directly" do
    frame = ID3V24::RVAFrame.default(-0.8)
    frame.left_peak = 6_553
    expect(frame.right_peak).to eq(0)
    expect(frame.left_peak).to eq(6_553)
  end
end

describe ID3V24::RVAFrame, "when parsing a simple RVAD (ID3v2.3 volume adjustment) frame containing one adjustment of -2dB" do
  before :all do
    @rvad = "\x02\x10\x34\xa7\x00\x01\x00\x00\x00\x00"
    @frame = ID3V24::Frame.create_frame_from_string("RVA", @rvad)
  end

  it "should be reconstituted as the correct class" do
    expect(@frame).to be_an_instance_of(ID3V24::RVAFrame)
  end

  it "should have a channel type of 'Front right'" do
    expect(@frame.adjustments.first.channel_type).to eq("Front right")
  end

  it "should have a channel adjustment value of -2 dB" do
    expect(@frame.adjustments.first.adjustment).to be_within(0.00002).of(-2.0)
  end

  it "should have a channel raw adjustment value of -1024" do
    expect(@frame.adjustments.first.raw_adjustment).to eq(-1024)
  end

  it "should have a peak gain adjustment of 0" do
    expect(@frame.adjustments.first.peak_gain).to eq(0)
  end
end

describe ID3V24::RVAFrame, "when parsing a simple RVAD (ID3v2.3 replaygain) frame containing one adjustment of 6dB and a peak gain adjustment" do
  before :all do
    @rvad = "\x03\x10\x95\xbc\x00\x01\x19\x99\x00\x00"
    @frame = ID3V24::Frame.create_frame_from_string("RVA", @rvad)
  end

  it "should be reconstituted as the correct class" do
    expect(@frame).to be_an_instance_of(ID3V24::RVAFrame)
  end

  it "should have a channel type of 'Front right'" do
    expect(@frame.adjustments.first.channel_type).to eq("Front right")
  end

  it "should have a channel adjustment value of 4.0 dB" do
    expect(@frame.adjustments.first.adjustment).to eq(4.0)
  end

  it "should have a channel raw adjustment value of 2,048" do
    expect(@frame.adjustments.first.raw_adjustment).to eq(2_048)
  end

  it "should have a peak gain adjustment of 6,553" do
    expect(@frame.adjustments.first.peak_gain).to eq(6_553)
  end

  it "should have a peak gain width of 16" do
    expect(@frame.adjustments.first.peak_gain_bit_width).to eq(16)
  end
end
