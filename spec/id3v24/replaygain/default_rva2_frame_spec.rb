# encoding: binary

describe ID3V24::RVA2Frame, "when creating a new RVA2 (replay gain) frame with defaults" do
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)

    @gain = 4.3
    tag = {"RVA2" => ID3V24::Frame.create_frame("RVA2", @gain)}
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag["RVA2"]
  end

  after :all do
    FileUtils.rm_f(@mp3_filename)
  end

  it "should reconstitute itself as the correct class" do
    expect(@saved_frame).to be_an_instance_of(ID3V24::RVA2Frame)
  end

  it "should default to adjusting track-level replay gain" do
    expect(@saved_frame.identifier).to eq("track")
  end

  it "should come with a single adjustment" do
    expect(@saved_frame.adjustments.size).to eq(1)
  end

  it "should preserve the gain adjustment set within a tolerance of the epsilon for the adjustment (0.001953125)" do
    expect(@saved_frame.adjustments.first.adjustment).to be_within(0.001953125).of(@gain)
  end

  it "should correctly calculate the raw adjustment value based on the dB value passed to the default generator" do
    expect(@saved_frame.adjustments.first.raw_adjustment).to eq(2201)
  end

  it "should have a peak gain adjustment scale 0 bits wide" do
    expect(@saved_frame.adjustments.first.peak_gain_bit_width).to eq(0)
  end

  it "should have a peak gain adjustment of 0" do
    expect(@saved_frame.adjustments.first.peak_gain).to eq(0)
  end

  it "should correctly encode itself to binary" do
    expect(@saved_frame.to_s).to eq("track\x00\x01\x08\x99\x00")
  end
end
