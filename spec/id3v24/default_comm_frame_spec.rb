$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::COMMFrame, "when creating a new COMM (comment) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @comment_text = "This is a sample comment."
    tag = { "COMM" => ID3V24::Frame.create_frame("COMM", @comment_text) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['COMM']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    expect(@saved_frame.class).to eq(ID3V24::COMMFrame)
  end
  
  it "should choose a default encoding for the description of the image of UTF-8" do
    expect(@saved_frame.encoding).to eq(ID3V24::TextFrame::ENCODING[:utf8])
  end
  
  it "should have a default description of 'Mp3Info Comment'" do
    expect(@saved_frame.description).to eq('Mp3Info Comment')
  end
  
  it "should default to being in English (sorry, non-English-speaking world)" do
    expect(@saved_frame.language).to eq('eng')
  end
  
  it "should retrieve the stored comment value correctly" do
    expect(@saved_frame.value).to eq(@comment_text)
  end
  
  it "should handle a nil comment value by producing a frame with an empty value" do
    tag = { "COMM" => ID3V24::Frame.create_frame("COMM", nil) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    saved_frame = saved_tag['COMM']
    
    expect(saved_frame.class).to eq(ID3V24::COMMFrame)
    expect(saved_frame.encoding).to eq(ID3V24::TextFrame::ENCODING[:utf8])
    expect(saved_frame.description).to eq('Mp3Info Comment')
    expect(saved_frame.language).to eq('eng')
    expect(saved_frame.value).to eq('')
  end
end
