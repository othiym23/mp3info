require 'mp3info/id3'

describe ID3, "when working with standalone ID3v1.0 tags" do

  it "should correctly identify the tag as ID3v1.0 and not ID3v1.1" do
    expect(ID3.new.from_bin(packed_id3_1_0_tag).version).to eq(ID3::VERSION_1)
  end

  it "should be able to retrieve the title from a ID3v1.0 tag" do
    expect(ID3.new.from_bin(packed_id3_1_0_tag)['title']).to eq(Mp3InfoHelper::TEST_TITLE)
  end

  it "should be able to retrieve the artist from an ID3v1.0 tag" do
    expect(ID3.new.from_bin(packed_id3_1_0_tag)['artist']).to eq(Mp3InfoHelper::TEST_ARTIST)
  end

  it "should be able to retrieve the album from an ID3v1.0 tag" do
    expect(ID3.new.from_bin(packed_id3_1_0_tag)['album']).to eq(Mp3InfoHelper::TEST_ALBUM)
  end

  it "should be able to retrieve the comments from an ID3v1.0 tag" do
    expect(ID3.new.from_bin(packed_id3_1_0_tag)['comments']).to eq(Mp3InfoHelper::TEST_COMMENT)
  end

  it "should be able to retrieve the genre ID from an ID3v1.0 tag" do
    expect(ID3.new.from_bin(packed_id3_1_0_tag)['genre']).to eq(Mp3InfoHelper::TEST_GENRE_ID)
  end

  it "should be able to retrieve the genre name from an ID3v1.0 tag" do
    expect(ID3.new.from_bin(packed_id3_1_0_tag)['genre_s']).to eq(Mp3InfoHelper::TEST_GENRE_NAME)
  end

  it "should not be able to retrieve the track number from an ID3v1.0 tag, because the tag doesn't contain it" do
    expect(ID3.new.from_bin(packed_id3_1_0_tag)['tracknum']).to be_nil
  end
end

describe ID3, "when working with standalone ID3v1.1 tags" do

  it "should correctly identify the tag as ID3v1.1 and not ID3v1.0" do
    expect(ID3.new.from_bin(packed_id3_1_1_tag).version).to eq(ID3::VERSION_1_1)
  end

  it "should be able to retrieve the title from an ID3v1.1 tag" do
    expect(ID3.new.from_bin(packed_id3_1_1_tag)['title']).to eq(Mp3InfoHelper::TEST_TITLE)
  end

  it "should be able to retrieve the artist from an ID3v1.1 tag" do
    expect(ID3.new.from_bin(packed_id3_1_1_tag)['artist']).to eq(Mp3InfoHelper::TEST_ARTIST)
  end

  it "should be able to retrieve the album from an ID3v1.1 tag" do
    expect(ID3.new.from_bin(packed_id3_1_1_tag)['album']).to eq(Mp3InfoHelper::TEST_ALBUM)
  end

  it "should be able to retrieve the comments from an ID3v1.1 tag" do
    expect(ID3.new.from_bin(packed_id3_1_1_tag)['comments']).to eq(Mp3InfoHelper::TEST_COMMENT)
  end

  it "should be able to retrieve the genre ID from an ID3v1.1 tag" do
    expect(ID3.new.from_bin(packed_id3_1_1_tag)['genre']).to eq(Mp3InfoHelper::TEST_GENRE_ID)
  end

  it "should be able to retrieve the genre name from an ID3v1.1 tag" do
    expect(ID3.new.from_bin(packed_id3_1_1_tag)['genre_s']).to eq(Mp3InfoHelper::TEST_GENRE_NAME)
  end

  it "should be able to retrieve the track number from an ID3v1.1 tag" do
    expect(ID3.new.from_bin(packed_id3_1_1_tag)['tracknum']).to eq(Mp3InfoHelper::TEST_TRACK_NUMBER)
  end

  it "should correctly name an invalid genre ID 'Unknown'" do
    tag = sample_id3v1_tag
    tag['genre'] = Mp3InfoHelper::INVALID_GENRE_ID

    expect(ID3.new.from_bin(packed_id3_1_1_tag(tag))['genre_s']).to eq("Unknown")
  end

  it "should be able to dump and then read a tag using bare-bones file operations" do
    filename = "sample_tag.tag"
    tag = ID3.new
    tag.update(sample_id3v1_tag)
    tag.to_file(filename)
    expect(ID3.from_file(filename)).to eq(sample_id3v1_tag)
    FileUtils.rm_f(filename)
  end
end
