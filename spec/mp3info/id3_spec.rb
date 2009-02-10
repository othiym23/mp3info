$:.unshift("spec/")

require 'mp3info/mp3info_helper'
require 'mp3info/id3'

describe Mp3Info, "when working with ID3v1 tags" do
  include Mp3InfoHelper

  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should be able to add the tag without error" do
    lambda { Mp3Info.open(@mp3_filename) { |info| info.id3v1_tag = sample_id3v1_tag } }.should_not raise_error
    Mp3Info.has_id3v1_tag?(@mp3_filename).should be_true
  end
  
  it "should be able to add and remove the tag without error" do
    lambda { Mp3Info.open(@mp3_filename) { |info| info.id3v1_tag = sample_id3v1_tag } }.should_not raise_error
    Mp3Info.has_id3v1_tag?(@mp3_filename).should be_true
    lambda { Mp3Info.removeid3v1_tag(@mp3_filename) }.should_not raise_error
    Mp3Info.has_id3v1_tag?(@mp3_filename).should be_false
  end

  it "should be able to add a tag and then remove it from within the open() block" do
    lambda { Mp3Info.open(@mp3_filename) { |info| info.id3v1_tag = sample_id3v1_tag } }.should_not raise_error
    Mp3Info.has_id3v1_tag?(@mp3_filename).should be_true
    lambda { Mp3Info.open(@mp3_filename) { |info| info.removeid3v1_tag } }.should_not raise_error(IOError, "closed stream")
    Mp3Info.has_id3v1_tag?(@mp3_filename).should be_false
  end
  
  it "should be able to add and then find a ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.has_id3v1_tag?(@mp3_filename).should be_true
  end
  
  it "should not have a tag until one is automatically created" do
    mp3 = Mp3Info.new(@mp3_filename)
    mp3.has_id3v1_tag?.should be_false
    mp3.id3v1_tag['artist'] = 'The Mighty Boosh'
    mp3.has_id3v1_tag?.should be_true
    mp3.id3v1_tag['artist'].should == 'The Mighty Boosh'
  end
  
  it "should create ID3v1.1 tags by default" do
    mp3 = Mp3Info.new(@mp3_filename)
    mp3.has_id3v1_tag?.should be_false
    mp3.id3v1_tag['tracknumber'] = 1
    mp3.has_id3v1_tag?.should be_true
    mp3.id3v1_tag.version.should == ID3::VERSION_1_1
  end
  
  it "should correctly identify the tag as ID3v1.0 and not ID3v1.1" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag.version.should == ID3::VERSION_1
  end
  
  it "should be able to find the title from a ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['title'].should == Mp3InfoHelper::TEST_TITLE
  end
  
  it "should be able to find the artist in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['artist'].should == Mp3InfoHelper::TEST_ARTIST
  end
  
  it "should be able to find the album in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['album'].should == Mp3InfoHelper::TEST_ALBUM
  end
  
  it "should be able to find the comments in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['comments'].should == Mp3InfoHelper::TEST_COMMENT
  end
  
  it "should be able to find the genre ID in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['genre'].should == Mp3InfoHelper::TEST_GENRE_ID
  end
  
  it "should be able to find the genre name in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['genre_s'].should == Mp3InfoHelper::TEST_GENRE_NAME
  end
  
  it "should not be able to find the track number in an ID3v1.0 tag, because the tag doesn't contain it" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['tracknum'].should == nil
  end
  
  it "should be able to add and then find an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.has_id3v1_tag?(@mp3_filename).should be_true
  end
  
  it "should correctly identify the tag as ID3v1.1 and not ID3v1.0" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag.version.should == ID3::VERSION_1_1
  end
  
  it "should be able to find the title in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['title'].should == Mp3InfoHelper::TEST_TITLE
  end
  
  it "should be able to find the artist in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['artist'].should == Mp3InfoHelper::TEST_ARTIST
  end
  
  it "should be able to find the album in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['album'].should == Mp3InfoHelper::TEST_ALBUM
  end
  
  it "should be able to find the comments in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['comments'].should == Mp3InfoHelper::TEST_COMMENT
  end
  
  it "should be able to find the genre ID in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['genre'].should == Mp3InfoHelper::TEST_GENRE_ID
  end
  
  it "should be able to find the genre name in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['genre_s'].should == Mp3InfoHelper::TEST_GENRE_NAME
  end
  
  it "should be able to find the track number in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).id3v1_tag['tracknum'].should == Mp3InfoHelper::TEST_TRACK_NUMBER
  end
  
  it "should correctly name an invalid genre ID 'Unknown'" do
    tag = sample_id3v1_tag
    tag['genre'] = Mp3InfoHelper::INVALID_GENRE_ID
    
    Mp3Info.open(@mp3_filename) { |info| info.id3v1_tag = tag }
    Mp3Info.new(@mp3_filename).id3v1_tag['genre_s'].should == "Unknown"
  end
end
