describe ID3V2, "when creating ID3v2 tags" do
  before do
    @tag = ID3V2.new
  end

  it "should create a tag that is valid by default" do
    expect(@tag.valid?).to be true
  end

  it "should create a tag with a major version of 4 by default" do
    expect(@tag.major_version).to eq(4)
  end

  it "should create a tag with a minor version of 0 by default" do
    expect(@tag.minor_version).to eq(0)
  end

  it "should create a tag with a full version of '2.4.0' by default" do
    expect(@tag.version).to eq('2.4.0')
  end

  it "should create a tag without unsynchronized frames by default" do
    expect(@tag.unsynchronized?).to be false
  end

  it "should create a tag with no extended header by default" do
    expect(@tag.extended_header?).to be false
  end

  it "should create tags that are not experimental (as if) by default" do
    expect(@tag.experimental?).to be false
  end

  it "should create a tag that does not have footers by default" do
    expect(@tag.footer?).to be false
  end

  it "should recognize an empty ID3v2.2 tag" do
    tag_string = "ID3\x02\x00\x00\x00\x00\x00\x00"
    @tag.from_bin(tag_string)
    expect(@tag.valid?).to be true
    expect(@tag.major_version).to eq(2)
    expect(@tag.minor_version).to eq(0)
    expect(@tag.version).to eq("2.2.0")
  end

  it "should be able to dump and then read a tag using bare-bones file operations" do
    filename = "sample_tag.id3"
    @tag.update(sample_id3v2_tag)
    @tag.to_file(filename)
    expect(ID3V2.from_file(filename)).to eq(sample_id3v2_tag)
    FileUtils.rm_f(filename)
  end
end
