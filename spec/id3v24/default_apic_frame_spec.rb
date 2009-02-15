$:.unshift("spec/")

require 'digest/sha1'
require 'mp3info/mp3info_helper'

describe ID3V24::APICFrame, "when creating a new APIC (picture) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)

    @random_data = random_string
    tag = { "APIC" => ID3V24::Frame.create_frame("APIC", @random_data) }
    @saved_frame = update_id3_2_tag(@mp3_filename, tag)['APIC']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::APICFrame
  end
  
  it "should choose a default encoding for the description of the image of UTF-8" do
    @saved_frame.encoding.should == ID3V24::TextFrame::ENCODING[:utf8]
  end
  
  it "should default to having a blank description" do
    @saved_frame.description.should == "cover image"
  end
  
  it "should default to having an image type of 'image/jpeg'" do
    @saved_frame.mime_type.should == 'image/jpeg'
  end
  
  it "should default to a picture type of 3 ('Cover (front)')" do
    @saved_frame.picture_type.should == "\x03"
  end
  
  it "should default to a picture type name of 'Cover (front)'" do
    @saved_frame.picture_type_name.should == "Cover (front)"
  end
  
  it "should safely retrieve the picture data" do
    Digest::SHA1.hexdigest(@saved_frame.value).should == Digest::SHA1.hexdigest(@random_data)
  end
  
  it "should have a consistent pretty description with default values set" do
    @saved_frame.to_s_pretty.should == "Attached Picture (cover image) of image type image/jpeg and class Cover (front) of size #{Mp3InfoHelper::TEST_PRIME}"
  end
end
