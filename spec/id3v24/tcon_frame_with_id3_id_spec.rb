$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::TCONFrame, "when creating a new TCON (genre) frame with a genre that corresponds to an ID3v1 genre ID" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @genre_name = "Jungle"
    tag = { "TCON" => ID3V24::Frame.create_frame("TCON", @genre_name) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['TCON']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::TCONFrame
  end
  
  it "should retrieve 'Jungle' as the bare genre name" do
    @saved_frame.value.should == @genre_name
  end
  
  it "should find the numeric genre ID for 'Jungle'" do
    @saved_frame.genre_code.should == 63
  end
  
  it "should pretty-print the genre name id3v2 style, as 'Name (id)'" do
    @saved_frame.to_s_pretty.should == "Jungle (63)"
  end
end
