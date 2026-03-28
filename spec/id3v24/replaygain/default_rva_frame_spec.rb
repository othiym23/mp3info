# encoding: binary

describe ID3V24::RVAFrame, "when creating a new RVAD (replay gain) frame with defaults" do
  
  before :all do
    @gain = 1.33
    @frame = ID3V24::Frame.create_frame("RVA", @gain)
  end
  
  it "should be the correct class" do
    expect(@frame).to be_an_instance_of(ID3V24::RVAFrame)
  end
  
  it "should have a volume bit width of 16 by default" do
    expect(@frame.bit_width).to eq(16)
  end
  
  it "should preserve the gain adjustment of the right channel within the epsilon at 16 bits' width (0.001953125)" do
    expect(@frame.right_gain).to be_within(0.001953125).of(@gain)
  end
  
  it "should have peak value on the right channel of 0" do
    expect(@frame.right_peak).to eq(0)
  end
  
  it "should preserve the gain adjustment of the left channel within the epsilon at 16 bits' width (0.001953125)" do
    expect(@frame.left_gain).to be_within(0.001953125).of(@gain)
  end
  
  it "should have peak value on the left channel of 0" do
    expect(@frame.left_peak).to eq(0)
  end
  
  it "should correctly encode itself to binary" do
    expect(@frame.to_s).to eq("\x03\x10\x2a\x5c\x2a\x5c\x00\x00\x00\x00")
  end
end
