describe ID3V24::TCMPFrame, "when creating a new TCMP (iTunes-specific compilation flag) frame" do
  
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should correctly indicate when the track is part of a compilation" do
    tag = { "TCMP" => ID3V24::Frame.create_frame("TCMP", true) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    expect(saved_tag['TCMP']).to be_an_instance_of(ID3V24::TCMPFrame)
    expect(saved_tag['TCMP'].value).to be true
    expect(saved_tag['TCMP'].to_s_pretty).to eq("This track is part of a compilation.")
  end
  
  it "should correctly indicate when the track is not part of a compilation" do
    tag = { "TCMP" => ID3V24::Frame.create_frame("TCMP", false) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    expect(saved_tag['TCMP']).to be_an_instance_of(ID3V24::TCMPFrame)
    expect(saved_tag['TCMP'].value).to be false
    expect(saved_tag['TCMP'].to_s_pretty).to eq("This track is not part of a compilation.")
  end
end
