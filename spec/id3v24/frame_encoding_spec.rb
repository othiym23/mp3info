$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe ID3V24::Frame, "when dealing with the various frame encoding types" do
  include Mp3InfoHelper
  
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should correctly handle ISO 8859-1 text" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Junior Citizen (lé Freak!)")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:iso]
    tag = { "TIT2" => tit2 }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    # ID3V24::TextFrame::ENCODING[:iso] => 0
    saved_tag['TIT2'].encoding.should == 0
    saved_tag['TIT2'].encoding.should == ID3V24::TextFrame::ENCODING[:iso]
    saved_tag['TIT2'].value.should == "Junior Citizen (lé Freak!)"
  end
  
  it "should correctly handle UTF-16 Unicode text with a byte-order mark" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:utf16]
    tag = { "TIT2" => tit2 }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    # ID3V24::TextFrame::ENCODING[:utf16] => 1
    saved_tag['TIT2'].encoding.should == 1
    saved_tag['TIT2'].encoding.should == ID3V24::TextFrame::ENCODING[:utf16]
    saved_tag['TIT2'].value.should == "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈"
  end
  
  it "should correctly handle big-endian UTF-16 Unicode text" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:utf16be]
    tag = { "TIT2" => tit2 }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    # ID3V24::TextFrame::ENCODING[:utf16be] => 2
    saved_tag['TIT2'].encoding.should == 2
    saved_tag['TIT2'].encoding.should == ID3V24::TextFrame::ENCODING[:utf16be]
    saved_tag['TIT2'].value.should == "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈"
  end
  
  it "should correctly handle UTF-8 Unicode text" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:utf8]
    tag = { "TIT2" => tit2 }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    # ID3V24::TextFrame::ENCODING[:utf8] => 3
    saved_tag['TIT2'].encoding.should == 3
    saved_tag['TIT2'].encoding.should == ID3V24::TextFrame::ENCODING[:utf8]
    saved_tag['TIT2'].value.should == "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈"
  end
  
  it "should raise a conversion error when trying to save Unicode text in an ISO 8859-1-encoded frame" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:iso]
    tag = { "TIT2" => tit2 }
    lambda { update_id3_2_tag(@mp3_filename, tag) }.should raise_error(Iconv::IllegalSequence)
  end
end
