$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe Mp3Info, "when comparing tagged files using the ID3lib-based command-line tool 'id3v2'" do
  include Mp3InfoHelper
  
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  # test the tag with the "id3v2" program -- you'll need a version of id3lib
  # that's been patched to work with ID3v2 2.4.0 tags, which probably means
  # a version of id3lib above 3.8.3
  it "should produce results equivalent to those produced by id3v2" do
    written_tag = update_id3_2_tag(@mp3_filename, sample_id3v2_tag)
    written_tag.should == sample_id3v2_tag
    
    pending("find a replacement for id3v2 because id3lib doesn't like UTF-8 values") do
      test_against_id3v2_prog(written_tag).should == prettify_tag(written_tag)
    end
  end
  
  it "should default having a pretty format identical to id3v2's" do
    comment_text = "This is a sample comment."
    tag = { "COMM" => ID3V24::Frame.create_frame("COMM", comment_text) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    saved_tag['COMM'].to_s_pretty.should == "(Mp3Info Comment)[eng]: This is a sample comment."
  end
  
  it "should produce output identical to id3v2's when compared" do
    pending("find a replacement for id3v2 because id3lib doesn't like UTF-8 values") do
      comment_text = "This is a sample comment."
      tag = { "COMM" => ID3V24::Frame.create_frame("COMM", comment_text) }
      saved_tag = update_id3_2_tag(@mp3_filename, tag)
      test_against_id3v2_prog(saved_tag).should == prettify_tag(saved_tag)
    end
  end
  
  it "should formate comment (COMM) frames identically to id3v2" do
    comment_text = "Ευφροσυνη"
    comm = ID3V24::Frame.create_frame("COMM", comment_text)
    comm.description = '::AOAIOXXYSZ:: Info'
    
    saved_tag = update_id3_2_tag(@mp3_filename, { "COMM" => comm })
    
    saved_tag['COMM'].to_s_pretty.should == "(::AOAIOXXYSZ:: Info)[eng]: Ευφροσυνη"
  end
  
  it "should produce output identical to id3v2's when compared" do
    pending("find a replacement for id3v2 because id3lib doesn't like UTF-8 values") do
      comment_text = "Track 5"
      comm = ID3V24::Frame.create_frame("COMM", comment_text)
      comm.description = '::AOAIOXXYSZ:: Info'
      
      saved_tag = update_id3_2_tag(@mp3_filename, { "COMM" => comm })
      
      test_against_id3v2_prog(saved_tag).should == prettify_tag(saved_tag)
    end
  end
  
  it "should default to having a pretty format identical to id3v2's, if id3v2 actually supported Unicode" do
    comment_text = "Здравствуйте dïáçrìtícs!"
    comm = ID3V24::Frame.create_frame("COMM", comment_text)
    comm.language = 'rus'
    
    saved_tag = update_id3_2_tag(@mp3_filename, { "COMM" => comm })
    saved_frame = saved_tag['COMM']
    
    saved_frame.to_s_pretty.should == "(Mp3Info Comment)[rus]: Здравствуйте dïáçrìtícs!"
  end
  
  it "should pretty-print TXXX frames in the style of id3v2" do
    user_text = "Here is some random user-defined text."
    new_tag = { "TXXX" => ID3V24::Frame.create_frame("TXXX", user_text) }
    saved_tag = update_id3_2_tag(@mp3_filename, new_tag)
    saved_frame = saved_tag['TXXX']
    
    saved_frame.to_s_pretty.should == "(Mp3Info Comment) : Here is some random user-defined text."
  end
  
  it "should pretty-print WXXX frames in the style of id3v2" do
    user_link = "http://www.yourmom.gov"
    new_tag = { "WXXX" => ID3V24::Frame.create_frame("WXXX", user_link) }
    saved_tag = update_id3_2_tag(@mp3_filename, new_tag)
    saved_frame = saved_tag['WXXX']
    
    saved_frame.to_s_pretty.should == "(Mp3Info User Link) : http://www.yourmom.gov"
  end
  
  it "should pretty-print TCON frames (genre name) id3v2 style, as 'Name (id)'" do
    genre_name = "Jungle"
    tag = { "TCON" => ID3V24::Frame.create_frame("TCON", genre_name) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    saved_frame = saved_tag['TCON']
    
    saved_frame.to_s_pretty.should == "Jungle (63)"
  end
  
  it "should pretty-print TCON frames (genre name) id3v2 style, as 'Name (255)'" do
    genre_name = "Experimental"
    tag = { "TCON" => ID3V24::Frame.create_frame("TCON", genre_name) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    saved_frame = saved_tag['TCON']
    
    saved_frame.to_s_pretty.should == "Experimental (255)"
  end
end
