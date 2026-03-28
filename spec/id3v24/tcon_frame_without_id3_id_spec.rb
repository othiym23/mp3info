describe ID3V24::TCONFrame, "when creating a new TCON (genre) frame with a genre with no genre ID" do
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @genre_name = "Experimental"
    tag = { "TCON" => ID3V24::Frame.create_frame("TCON", @genre_name) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['TCON']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    expect(@saved_frame).to be_an_instance_of(ID3V24::TCONFrame)
  end
  
  it "should retrieve 'Experimental' as the bare genre name" do
    expect(@saved_frame.value).to eq(@genre_name)
  end
  
  it "should fail to find a numeric genre ID for 'Experimental' and use 255 instead" do
    expect(@saved_frame.genre_code).to eq(255)
  end
end
