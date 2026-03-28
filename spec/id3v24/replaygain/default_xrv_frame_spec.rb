# encoding: binary

describe ID3V24::XRVFrame, "when creating a new XRV (ID3v2.2 replay gain) frame with defaults" do
  
  before :all do
    @gain = 4.3
    @frame = ID3V24::Frame.create_frame("XRV", @gain)
  end
  
  it "should be the correct class" do
    expect(@frame).to be_an_instance_of(ID3V24::XRVFrame)
  end
  
  it "should default to adjusting track-level replay gain" do
    expect(@frame.identifier).to eq('track')
  end
  
  it "should come with a single adjustment" do
    expect(@frame.adjustments.size).to eq(1)
  end
  
  it "should preserve the gain adjustment set within a tolerance of the epsilon for the adjustment (0.001953125)" do
    expect(@frame.adjustments.first.adjustment).to be_within(0.001953125).of(@gain)
  end
  
  it "should correctly calculate the raw adjustment value based on the dB value passed to the default generator" do
    expect(@frame.adjustments.first.raw_adjustment).to eq(2201)
  end
  
  it "should have a peak gain adjustment scale 0 bits wide" do
    expect(@frame.adjustments.first.peak_gain_bit_width).to eq(0)
  end
  
  it "should have a peak gain adjustment of 0" do
    expect(@frame.adjustments.first.peak_gain).to eq([])
  end
  
  it "should correctly encode itself to binary" do
    expect(@frame.to_s).to eq("track\x00\x01\x08\x99\x00")
  end
end
