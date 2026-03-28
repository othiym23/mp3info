$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::TXXXFrame, "when creating a new TXXX (user-defined text) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @user_text = "Here is some random user-defined text."
    @new_tag = { "TXXX" => ID3V24::Frame.create_frame("TXXX", @user_text) }
    @saved_tag = update_id3_2_tag(@mp3_filename, @new_tag)
    @saved_frame = @saved_tag['TXXX']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    expect(@saved_frame.class).to eq(ID3V24::TXXXFrame)
  end
  
  it "should be saved as UTF-8 Unicode text by default" do
    expect(@saved_frame.encoding).to eq(ID3V24::TextFrame::ENCODING[:utf8])
  end
  
  it "should have 'Mp3Info Comment' as its default description (this should be overridden in practice)" do
    expect(@saved_frame.description).to eq('Mp3Info Comment')
  end
  
  it "should safely retrieve its value" do
    expect(@saved_frame.value).to eq(@user_text)
  end
  
  it "should be directly comparable as a whole frame" do
    expect(@saved_frame).to eq(@new_tag['TXXX'])
  end
end
