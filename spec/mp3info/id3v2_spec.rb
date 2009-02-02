$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe Mp3Info, "when working with ID3v2 tags" do
  include Mp3InfoHelper
  
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @trivial_id3v2_tag = {"TIT2" => ID3V24::Frame.create_frame('TIT2', "sdfqdsf")}
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should be able to add the tag without error" do
    finish_tag = {}
    lambda { finish_tag = update_id3_2_tag(@mp3_filename, @trivial_id3v2_tag) }.should_not raise_error(Mp3InfoError)
    finish_tag.should == @trivial_id3v2_tag
  end
  
  it "should be able to add and remove the tag without error" do
    update_id3_2_tag(@mp3_filename, @trivial_id3v2_tag)
    
    Mp3Info.hastag2?(@mp3_filename).should be_true
    Mp3Info.removetag2(@mp3_filename)
    Mp3Info.hastag2?(@mp3_filename).should be_false
  end
  
  it "should be able to add the tag and then remove it from within the open() block" do
    update_id3_2_tag(@mp3_filename, @trivial_id3v2_tag)
    
    Mp3Info.hastag2?(@mp3_filename).should be_true
    lambda { Mp3Info.open(@mp3_filename) { |info| info.removetag2 } }.should_not raise_error(Mp3InfoError)
    Mp3Info.hastag2?(@mp3_filename).should be_false
  end
  
  it "should be able to discover the version of the ID3v2 tag written to disk" do
    update_id3_2_tag(@mp3_filename, sample_id3v2_tag).version.should == "2.4.0"
  end
  
  it "should be able to treat each ID3v2 frame as a directly-accessible attribute of the tag" do
    tag = {
      "TIT2" => ID3V24::Frame.create_frame("TIT2", "tit2"),
      "TPE1" => ID3V24::Frame.create_frame("TPE1", "tpe1")
      }
    
    # Do it once with the hackish HashKeys direct method...
    Mp3Info.open(@mp3_filename) do |mp3|
      mp3.tag2.TIT2 = "tit2"
      mp3.tag2.TPE1 = "tpe1"
      
      mp3.tag2.should == tag
    end
    
    # ...and again with direct message sending to invoke the HashKeys delegation
    Mp3Info.open(@mp3_filename) do |mp3|
      tag.each do |k, v|
        mp3.tag2.send("#{k}=".to_sym, v)
      end
      
      mp3.tag2.should == tag
    end
  end
  
  # test the tag with the "id3v2" program -- you'll need a version of id3lib
  # that's been patched to work with ID3v2 2.4.0 tags, which probably means
  # a version of id3lib above 3.8.3
  it "should produce results equivalent to those produced by the id3v2 utility" do
    written_tag = update_id3_2_tag(@mp3_filename, sample_id3v2_tag)
    written_tag.should == sample_id3v2_tag
    
    test_against_id3v2_prog(written_tag).should == prettify_tag(written_tag)
  end
  
  it "should handle storing and retrieving tags containing arbitrary binary data" do
    tag = {}
    ["PRIV", "XNBC", "APIC", "XNXT"].each do |k|
      tag[k] = ID3V24::Frame.create_frame(k, random_string)
    end
    
    update_id3_2_tag(@mp3_filename, tag).should == tag
  end
  
  it "should handle storing tags via the tag update mechanism in mp3info's open() block" do
    tag = {}
    ["PRIV", "XNBC", "APIC", "XNXT"].each do |k|
      tag[k] = ID3V24::Frame.create_frame(k, random_string)
    end
    
    Mp3Info.open(@mp3_filename) do |mp3|
      # before update
      mp3.tag2.should == {}
      mp3.tag2.update(tag)
    end
    
    # after update has been saved
    Mp3Info.open(@mp3_filename) { |m| m.tag2 }.should == tag
  end
  
  it "should read an ID3v2 tag from a truncated MP3 file" do
    lambda { mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/zovietfrance/Popular Soviet Songs And Youth Music disc 3/zovietfrance - Popular Soviet Songs And Youth Music - 08 - Shewel.mp3')) }.should_not raise_error
  end
  
  it "should still read the tag from a truncated MP3 file" do
    lambda { mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/230-unicode.tag')) }.should_not raise_error
  end
  
  it "should make it easy to casually use ID3v2 tags" do
    Mp3Info.open(@mp3_filename) do |mp3|
      mp3.tag2['WCOM'] = "http://www.riaa.org/"
      mp3.tag2['TXXX'] = "A sample comment"
    end
    
    mp3 = Mp3Info.new(@mp3_filename)
    saved_tag = mp3.tag2
    
    saved_tag['WCOM'].value.should == "http://www.riaa.org/"
    saved_tag['TXXX'].value.should == "A sample comment"
  end
end
