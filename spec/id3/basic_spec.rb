$:.unshift("spec/")

require 'mp3info/mp3info_helper'
require 'mp3info/id3'

describe ID3, "when working with standalone ID3 tags" do
  include Mp3InfoHelper
  
  it "should correctly identify the tag as ID3v1.0 and not ID3v1.1" do
    ID3.new.from_bin(packed_id3_1_0_tag).version.should == ID3::VERSION_1
  end
  
  it "should be able to find the title from a ID3v1.0 tag" do
    ID3.new.from_bin(packed_id3_1_0_tag)['title'].should == Mp3InfoHelper::TEST_TITLE
  end
  
  it "should be able to find the artist in an ID3v1.0 tag" do
    ID3.new.from_bin(packed_id3_1_0_tag)['artist'].should == Mp3InfoHelper::TEST_ARTIST
  end
  
  it "should be able to find the album in an ID3v1.0 tag" do
    ID3.new.from_bin(packed_id3_1_0_tag)['album'].should == Mp3InfoHelper::TEST_ALBUM
  end
  
  it "should be able to find the comments in an ID3v1.0 tag" do
    ID3.new.from_bin(packed_id3_1_0_tag)['comments'].should == Mp3InfoHelper::TEST_COMMENT
  end
  
  it "should be able to find the genre ID in an ID3v1.0 tag" do
    ID3.new.from_bin(packed_id3_1_0_tag)['genre'].should == Mp3InfoHelper::TEST_GENRE_ID
  end
  
  it "should be able to find the genre name in an ID3v1.0 tag" do
    ID3.new.from_bin(packed_id3_1_0_tag)['genre_s'].should == Mp3InfoHelper::TEST_GENRE_NAME
  end
  
  it "should not be able to find the track number in an ID3v1.0 tag, because the tag doesn't contain it" do
    ID3.new.from_bin(packed_id3_1_0_tag)['tracknum'].should == nil
  end
  
  it "should correctly identify the tag as ID3v1.1 and not ID3v1.0" do
    ID3.new.from_bin(packed_id3_1_1_tag).version.should == ID3::VERSION_1_1
  end
  
  it "should be able to find the title in an ID3v1.1 tag" do
    ID3.new.from_bin(packed_id3_1_1_tag)['title'].should == Mp3InfoHelper::TEST_TITLE
  end
  
  it "should be able to find the artist in an ID3v1.1 tag" do
    ID3.new.from_bin(packed_id3_1_1_tag)['artist'].should == Mp3InfoHelper::TEST_ARTIST
  end
  
  it "should be able to find the album in an ID3v1.1 tag" do
    ID3.new.from_bin(packed_id3_1_1_tag)['album'].should == Mp3InfoHelper::TEST_ALBUM
  end
  
  it "should be able to find the comments in an ID3v1.1 tag" do
    ID3.new.from_bin(packed_id3_1_1_tag)['comments'].should == Mp3InfoHelper::TEST_COMMENT
  end
  
  it "should be able to find the genre ID in an ID3v1.1 tag" do
    ID3.new.from_bin(packed_id3_1_1_tag)['genre'].should == Mp3InfoHelper::TEST_GENRE_ID
  end
  
  it "should be able to find the genre name in an ID3v1.1 tag" do
    ID3.new.from_bin(packed_id3_1_1_tag)['genre_s'].should == Mp3InfoHelper::TEST_GENRE_NAME
  end
  
  it "should be able to find the track number in an ID3v1.1 tag" do
    ID3.new.from_bin(packed_id3_1_1_tag)['tracknum'].should == Mp3InfoHelper::TEST_TRACK_NUMBER
  end
  
  it "should correctly name an invalid genre ID 'Unknown'" do
    tag = sample_id3v1_tag
    tag['genre'] = Mp3InfoHelper::INVALID_GENRE_ID
    
    ID3.new.from_bin(packed_id3_1_1_tag(tag))['genre_s'].should == "Unknown"
  end
  
  it "should be able to dump and then read a tag using bare-bones file operations" do
    filename = "sample_tag.tag"
    tag = ID3.new
    tag.update(sample_id3v1_tag)
    tag.to_file(filename)
    ID3.from_file(filename).should == sample_id3v1_tag
    FileUtils.rm_f(filename)
  end
end
