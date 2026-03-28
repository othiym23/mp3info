describe ID3V24::PRIVFrame, "when creating a new PRIV (private data) frame with defaults" do
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    # Base64 encode the data because for this test I want to test the defaults, not binary storage
    @random_data = Base64::encode64(random_string)
    tag = { "PRIV" => ID3V24::Frame.create_frame("PRIV", @random_data) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['PRIV']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    expect(@saved_frame.class).to eq(ID3V24::PRIVFrame)
  end
  
  it "should default to being owned by me (sure, why not?)" do
    expect(@saved_frame.owner).to eq('mailto:ogd@aoaioxxysz.net')
  end
  
  it "should retrieve the stored private data correctly" do
    expect(@saved_frame.value).to eq(@random_data)
  end
  
  it "should produce a useful pretty-printed representation" do
    expect(@saved_frame.to_s_pretty).to eq("PRIVATE DATA (from mailto:ogd@aoaioxxysz.net) [#{@random_data.inspect}]")
  end
end
