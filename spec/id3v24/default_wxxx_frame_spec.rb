describe ID3V24::WXXXFrame, "when creating a new WXXX (user-defined link) frame with defaults" do
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)

    @user_link = "http://www.yourmom.gov"
    @new_tag = {"WXXX" => ID3V24::Frame.create_frame("WXXX", @user_link)}
    @saved_tag = update_id3_2_tag(@mp3_filename, @new_tag)
    @saved_frame = @saved_tag["WXXX"]
  end

  after :all do
    FileUtils.rm_f(@mp3_filename)
  end

  it "should have been reconstituted as the correct class" do
    expect(@saved_frame).to be_an_instance_of(ID3V24::WXXXFrame)
  end

  it "should have a description encoded as UTF-8 text by default" do
    expect(@saved_frame.encoding).to eq(ID3V24::TextFrame::ENCODING[:utf8])
  end

  it "should have 'Mp3Info User Link' as its default description (this should be overridden in practice)" do
    expect(@saved_frame.description).to eq("Mp3Info User Link")
  end

  it "should safely retrieve its value" do
    expect(@saved_frame.value).to eq(@user_link)
  end

  it "should be directly comparable as a whole frame" do
    expect(@saved_frame).to eq(@new_tag["WXXX"])
  end
end
