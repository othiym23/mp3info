# encoding: binary

describe ID3V24::RGADFrame, "when creating a new RGAD (replay gain) frame with defaults" do
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)

    @gain = 4.3
    tag = {"RGAD" => ID3V24::Frame.create_frame("RGAD", @gain)}
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag["RGAD"]
  end

  after :all do
    FileUtils.rm_f(@mp3_filename)
  end

  it "should reconstitute itself as the correct class" do
    expect(@saved_frame).to be_an_instance_of(ID3V24::RGADFrame)
  end

  it "should be valid" do
    expect(@saved_frame.track_gain.valid?).to be true
    expect(@saved_frame.album_gain.valid?).to be true
    expect(@saved_frame.valid?).to be true
  end

  it "should show the track gain adjustment of being the 'track' type" do
    expect(@saved_frame.track_gain.type).to eq("track")
  end

  it "should show the track gain adjustment as having an origin of 'automatic'" do
    expect(@saved_frame.track_gain.origin).to eq("automatic")
  end

  it "should preserve the track gain adjustment set within a tolerance of the epsilon for the adjustment (0.001953125)" do
    expect(@saved_frame.track_gain.adjustment).to eq(@gain)
  end

  it "should correctly calculate the raw track gain adjustment value based on the dB value passed to the default generator" do
    expect(@saved_frame.track_gain.raw_adjustment).to eq(43)
  end

  it "should show the album gain adjustment of being the 'album' type" do
    expect(@saved_frame.album_gain.type).to eq("album")
  end

  it "should show the album gain adjustment as having an origin of 'automatic'" do
    expect(@saved_frame.album_gain.origin).to eq("automatic")
  end

  it "should preserve the album gain adjustment set within a tolerance of the epsilon for the adjustment (0.001953125)" do
    expect(@saved_frame.album_gain.adjustment).to eq(@gain)
  end

  it "should correctly calculate the raw album gain adjustment value based on the dB value passed to the default generator" do
    expect(@saved_frame.album_gain.raw_adjustment).to eq(43)
  end

  it "should have a peak amplitude of 0.0" do
    expect(@saved_frame.peak).to eq(0.0)
  end

  it "should correctly encode itself to binary" do
    expect(@saved_frame.to_s).to eq("\x00\x00\x00\x00\x2c\x2b\x4c\x2b")
  end
end
