require 'mp3info/id3'

describe Mp3Info, "when working with ID3v1 tags" do

  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should be able to add the tag without error" do
    expect { Mp3Info.open(@mp3_filename) { |info| info.id3v1_tag = sample_id3v1_tag } }.not_to raise_error
    expect(ID3.has_id3v1_tag?(@mp3_filename)).to be true
  end
  
  it "should be able to add and remove the tag without error" do
    expect { Mp3Info.open(@mp3_filename) { |info| info.id3v1_tag = sample_id3v1_tag } }.not_to raise_error
    expect(ID3.has_id3v1_tag?(@mp3_filename)).to be true
    expect { ID3.remove_id3v1_tag!(@mp3_filename) }.not_to raise_error
    expect(ID3.has_id3v1_tag?(@mp3_filename)).to be false
  end

  it "should be able to add a tag and then remove it from within the open() block" do
    expect { Mp3Info.open(@mp3_filename) { |info| info.id3v1_tag = sample_id3v1_tag } }.not_to raise_error
    expect(ID3.has_id3v1_tag?(@mp3_filename)).to be true
    expect { Mp3Info.open(@mp3_filename) { |info| info.remove_id3v1_tag } }.not_to raise_error
    expect(ID3.has_id3v1_tag?(@mp3_filename)).to be false
  end
  
  it "should be able to add and then find a ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    expect(ID3.has_id3v1_tag?(@mp3_filename)).to be true
  end
  
  it "should not have a tag until one is automatically created" do
    mp3 = Mp3Info.new(@mp3_filename)
    expect(mp3.has_id3v1_tag?).to be false
    mp3.id3v1_tag['artist'] = 'The Mighty Boosh'
    expect(mp3.has_id3v1_tag?).to be true
    expect(mp3.id3v1_tag['artist']).to eq('The Mighty Boosh')
  end
  
  it "should create ID3v1.1 tags by default" do
    mp3 = Mp3Info.new(@mp3_filename)
    expect(mp3.has_id3v1_tag?).to be false
    mp3.id3v1_tag['tracknumber'] = 1
    expect(mp3.has_id3v1_tag?).to be true
    expect(mp3.id3v1_tag.version).to eq(ID3::VERSION_1_1)
  end
  
  it "should correctly identify the tag as ID3v1.0 and not ID3v1.1" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag.version).to eq(ID3::VERSION_1)
  end
  
  it "should be able to find the title from a ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['title']).to eq(Mp3InfoHelper::TEST_TITLE)
  end
  
  it "should be able to find the artist in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['artist']).to eq(Mp3InfoHelper::TEST_ARTIST)
  end
  
  it "should be able to find the album in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['album']).to eq(Mp3InfoHelper::TEST_ALBUM)
  end
  
  it "should be able to find the comments in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['comments']).to eq(Mp3InfoHelper::TEST_COMMENT)
  end
  
  it "should be able to find the genre ID in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['genre']).to eq(Mp3InfoHelper::TEST_GENRE_ID)
  end
  
  it "should be able to find the genre name in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['genre_s']).to eq(Mp3InfoHelper::TEST_GENRE_NAME)
  end
  
  it "should not be able to find the track number in an ID3v1.0 tag, because the tag doesn't contain it" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['tracknum']).to eq(nil)
  end
end

describe Mp3Info, "when working with ID3v1.1 tags" do

  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should be able to add and then find an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    expect(ID3.has_id3v1_tag?(@mp3_filename)).to be true
  end
  
  it "should correctly identify the tag as ID3v1.1 and not ID3v1.0" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag.version).to eq(ID3::VERSION_1_1)
  end
  
  it "should be able to find the title in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['title']).to eq(Mp3InfoHelper::TEST_TITLE)
  end
  
  it "should be able to find the artist in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['artist']).to eq(Mp3InfoHelper::TEST_ARTIST)
  end
  
  it "should be able to find the album in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['album']).to eq(Mp3InfoHelper::TEST_ALBUM)
  end
  
  it "should be able to find the comments in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['comments']).to eq(Mp3InfoHelper::TEST_COMMENT)
  end
  
  it "should be able to find the genre ID in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['genre']).to eq(Mp3InfoHelper::TEST_GENRE_ID)
  end
  
  it "should be able to find the genre name in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['genre_s']).to eq(Mp3InfoHelper::TEST_GENRE_NAME)
  end
  
  it "should be able to find the track number in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['tracknum']).to eq(Mp3InfoHelper::TEST_TRACK_NUMBER)
  end
  
  it "should correctly name an invalid genre ID 'Unknown'" do
    tag = sample_id3v1_tag
    tag['genre'] = Mp3InfoHelper::INVALID_GENRE_ID
    
    Mp3Info.open(@mp3_filename) { |info| info.id3v1_tag = tag }
    expect(Mp3Info.new(@mp3_filename).id3v1_tag['genre_s']).to eq("Unknown")
  end
end
