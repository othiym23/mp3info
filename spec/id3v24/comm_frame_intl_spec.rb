describe ID3V24::COMMFrame, "when creating a new COMM (comment) frame containing Russian (and other Unicode)" do
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)

    @comment_text = "Здравствуйте dïáçrìtícs!"
    comm = ID3V24::Frame.create_frame("COMM", @comment_text)
    comm.language = "rus"
    tag = {"COMM" => comm}
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag["COMM"]
  end

  after :all do
    FileUtils.rm_f(@mp3_filename)
  end

  it "should be in Russian" do
    expect(@saved_frame.language).to eq("rus")
  end

  it "should retrieve the stored comment value correctly" do
    expect(@saved_frame.value).to eq(@comment_text)
  end
end
