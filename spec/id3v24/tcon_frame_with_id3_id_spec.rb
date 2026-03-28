describe ID3V24::TCONFrame, "when creating a new TCON (genre) frame with a genre that corresponds to an ID3v1 genre ID" do
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)

    @genre_name = "Jungle"
    tag = {"TCON" => ID3V24::Frame.create_frame("TCON", @genre_name)}
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag["TCON"]
  end

  after :all do
    FileUtils.rm_f(@mp3_filename)
  end

  it "should have been reconstituted as the correct class" do
    expect(@saved_frame).to be_an_instance_of(ID3V24::TCONFrame)
  end

  it "should retrieve 'Jungle' as the bare genre name" do
    expect(@saved_frame.value).to eq(@genre_name)
  end

  it "should find the numeric genre ID for 'Jungle'" do
    expect(@saved_frame.genre_code).to eq(63)
  end
end

describe ID3V24::TCONFrame, "when creating a new TCON (genre) frame with a bare ID3v1 genre ID" do
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)

    @genre_name = "Jungle"

    @genre_code_string = "63"
    tag = {"TCON" => ID3V24::Frame.create_frame("TCON", @genre_code_string)}
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag["TCON"]
  end

  after :all do
    FileUtils.rm_f(@mp3_filename)
  end

  it "should have been reconstituted as the correct class" do
    expect(@saved_frame).to be_an_instance_of(ID3V24::TCONFrame)
  end

  it "should retrieve 'Jungle' as the bare genre name" do
    expect(@saved_frame.value).to eq(@genre_name)
  end

  it "should find the numeric genre ID for 'Jungle'" do
    expect(@saved_frame.genre_code).to eq(63)
  end
end
