# encoding: binary

describe ID3V24::RVADFrame, "when creating a new RVAD (replay gain) frame with defaults" do
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @gain = 1.33
    tag = { "RVAD" => ID3V24::Frame.create_frame("RVAD", @gain) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['RVAD']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should reconstitute itself as the correct class" do
    expect(@saved_frame).to be_an_instance_of(ID3V24::RVADFrame)
  end
  
  it "should have a volume bit width of 16 by default" do
    expect(@saved_frame.bit_width).to eq(16)
  end
  
  it "should have adjustments made to the right channel by default" do
    expect(@saved_frame.channel_adjusted?(ID3V24::RVADFrame::FRONT_RIGHT)).to be true
  end
  
  it "should preserve the gain adjustment of the right channel within the epsilon at 16 bits' width (0.001953125)" do
    expect(@saved_frame.right_gain).to be_within(0.001953125).of(@gain)
  end
  
  it "should have peak value on the right channel of 0" do
    expect(@saved_frame.right_peak).to eq(0)
  end
  
  it "should have adjustments made to the left channel by default" do
    expect(@saved_frame.channel_adjusted?(ID3V24::RVADFrame::FRONT_LEFT)).to be true
  end
  
  it "should preserve the gain adjustment of the left channel within the epsilon at 16 bits' width (0.001953125)" do
    expect(@saved_frame.left_gain).to be_within(0.001953125).of(@gain)
  end
  
  it "should have peak value on the left channel of 0" do
    expect(@saved_frame.left_peak).to eq(0)
  end
  
  it "should correctly encode itself to binary" do
    expect(@saved_frame.to_s).to eq("\x03\x10\x2a\x5c\x2a\x5c\x00\x00\x00\x00")
  end
  
  it "should correctly state that the rear right channel is not adjusted" do
    expect(@saved_frame.channel_adjusted?(ID3V24::RVADFrame::REAR_RIGHT)).to be false
  end
  
  it "should correctly state that the rear left channel is not adjusted" do
    expect(@saved_frame.channel_adjusted?(ID3V24::RVADFrame::REAR_LEFT)).to be false
  end
  
  it "should correctly state that the center channel is not adjusted" do
    expect(@saved_frame.channel_adjusted?(ID3V24::RVADFrame::CENTER)).to be false
  end
  
  it "should correctly state that the subwoofer channel is not adjusted" do
    expect(@saved_frame.channel_adjusted?(ID3V24::RVADFrame::SUBWOOFER)).to be false
  end
end
