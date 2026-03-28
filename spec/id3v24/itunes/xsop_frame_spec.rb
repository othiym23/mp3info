describe ID3V24::XSOPFrame, "when dealing with the iTunes and ID3v2.3-specific XSOP (artist sort order) frame" do
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @artist_the = "Clash, The"
    tag = { "XSOP" => ID3V24::Frame.create_frame("XSOP", @artist_the) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['XSOP']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    expect(@saved_frame.class).to eq(ID3V24::XSOPFrame)
  end
  
  it "should reconstitute the artist sort name properly" do
    expect(@saved_frame.value).to eq(@artist_the)
  end
  
  it "should pretty-print the artist sort name identically to printing its raw value" do
    expect(@saved_frame.to_s_pretty).to eq(@artist_the)
  end
end
