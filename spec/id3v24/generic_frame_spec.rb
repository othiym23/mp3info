require "digest/sha1"

describe ID3V24::Frame, "when working with individual frames" do
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)

    @trivial_id3v2_tag = {"TIT2" => ID3V24::Frame.create_frame("TIT2", "sdfqdsf")}
  end

  after do
    FileUtils.rm_f(@mp3_filename)
  end

  it "should create a raw frame when given an unknown frame ID" do
    expect(ID3V24::Frame.create_frame("XXXX", 0)).to be_an_instance_of(ID3V24::Frame)
  end

  it "should gracefully handle unknown frame types" do
    crud = random_string
    tag = {"XNXT" => ID3V24::Frame.create_frame("XNXT", crud)}
    saved_tag = update_id3_2_tag(@mp3_filename, tag)

    expect(saved_tag["XNXT"]).to be_an_instance_of(ID3V24::Frame)
    expect(saved_tag["XNXT"].value.size).to eq(crud.size)
    expect(Digest::SHA1.hexdigest(saved_tag["XNXT"].to_s_pretty)).to eq(Digest::SHA1.hexdigest(crud))
    expect(saved_tag["XNXT"].frame_info).to eq("No description available for frame type 'XNXT'.")
  end

  it "should create a generic text frame when given an unknown Txxx frame ID" do
    expect(ID3V24::Frame.create_frame("TPOS", "1/14")).to be_an_instance_of(ID3V24::TextFrame)
  end

  it "should create a link frame when given an unknown Wxxx frame ID" do
    expect(ID3V24::Frame.create_frame("WOAR", "http://www.dresdendolls.com/")).to be_an_instance_of(ID3V24::LinkFrame)
  end

  it "should create a custom frame type when given a custom ID (TCON)" do
    expect(ID3V24::Frame.create_frame("TCON", "Experimetal")).to be_an_instance_of(ID3V24::TCONFrame)
  end

  it "should correctly retrieve the description for the conductor frame" do
    tag = {"TPE3" => ID3V24::Frame.create_frame("TPE3", "Leopold Stokowski")}
    saved_tag = update_id3_2_tag(@mp3_filename, tag)

    expect(saved_tag["TPE3"]).to be_an_instance_of(ID3V24::TextFrame)
    expect(saved_tag["TPE3"].value).to eq("Leopold Stokowski")
    expect(saved_tag["TPE3"].to_s_pretty).to eq("Leopold Stokowski")
    expect(saved_tag["TPE3"].frame_info).to eq("The 'Conductor' frame is used for the name of the conductor.")
  end

  it "should correctly retrieve the description for the original audio link frame" do
    tag = {"WOAF" => ID3V24::Frame.create_frame("WOAF", "http://example.com/audio.html")}
    saved_tag = update_id3_2_tag(@mp3_filename, tag)

    expect(saved_tag["WOAF"]).to be_an_instance_of(ID3V24::LinkFrame)
    expect(saved_tag["WOAF"].value).to eq("http://example.com/audio.html")
    expect(saved_tag["WOAF"].to_s_pretty).to eq("URL: http://example.com/audio.html")
    expect(saved_tag["WOAF"].frame_info).to eq("The 'Official audio file webpage' frame is a URL pointing at a file specific webpage.")
  end

  it "should correctly store lots of binary data in a frame" do
    tag = {"APIC" => ID3V24::Frame.create_frame("APIC", random_string)}
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    expect(saved_tag["APIC"].value.size).to eq(Mp3InfoHelper::TEST_PRIME)
    expect(saved_tag).to eq(tag)
  end
end
