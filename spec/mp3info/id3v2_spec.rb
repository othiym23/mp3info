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
    file_size = File.stat(@mp3_filename).size
    update_id3_2_tag(@mp3_filename, @trivial_id3v2_tag)
    File.stat(@mp3_filename).size.should > file_size
    
    Mp3Info.has_id3v2_tag?(@mp3_filename).should be_true
    Mp3Info.remove_id3v2_tag(@mp3_filename)
    Mp3Info.has_id3v2_tag?(@mp3_filename).should be_false
  end
  
  it "should be able to add the tag and then remove it from within the open() block" do
    update_id3_2_tag(@mp3_filename, @trivial_id3v2_tag)
    
    Mp3Info.has_id3v2_tag?(@mp3_filename).should be_true
    lambda { Mp3Info.open(@mp3_filename) { |info| info.remove_id3v2_tag } }.should_not raise_error(Mp3InfoError)
    Mp3Info.has_id3v2_tag?(@mp3_filename).should be_false
  end
  
  it "should not have a tag until one is automatically created" do
    mp3 = Mp3Info.new(@mp3_filename)
    mp3.has_id3v2_tag?.should be_false
    mp3.id3v2_tag['TPE1'] = 'The Mighty Boosh'
    mp3.has_id3v2_tag?.should be_true
    mp3.id3v2_tag['TPE1'].value.should == 'The Mighty Boosh'
  end
  
  it "should create ID3v2.4.0 tags by default" do
    mp3 = Mp3Info.new(@mp3_filename)
    mp3.has_id3v2_tag?.should be_false
    mp3.id3v2_tag['TRCK'] = "1/8"
    mp3.has_id3v2_tag?.should be_true
    mp3.id3v2_tag.version.should == "2.4.0"
  end
  
  it "should be able to discover the version of the ID3v2 tag written to disk" do
    update_id3_2_tag(@mp3_filename, sample_id3v2_tag).version.should == "2.4.0"
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
      mp3.has_id3v2_tag?.should be_false
      mp3.id3v2_tag = ID3V2.new
      mp3.id3v2_tag.update(tag)
    end
    
    # after update has been saved
    Mp3Info.open(@mp3_filename) { |m| m.id3v2_tag }.should == tag
  end
  
  it "should read an ID3v2 tag from a truncated MP3 file" do
    lambda { mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/zovietfrance/Popular Soviet Songs And Youth Music disc 3/zovietfrance - Popular Soviet Songs And Youth Music - 08 - Shewel.mp3')) }.should_not raise_error
  end
  
  it "should still read the tag from a truncated MP3 file" do
    lambda { mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/230-unicode.tag')) }.should_not raise_error
  end
  
  it "should default to not exposing the ID3v2 tag for casual use until it's had a frame added" do
    Mp3Info.open(@mp3_filename) do |mp3|
      mp3.has_id3v2_tag?.should be_false
    end
  end
  
  it "should make it easy to casually use ID3v2 tags" do
    Mp3Info.open(@mp3_filename) do |mp3|
      mp3.id3v2_tag = ID3V2.new
      mp3.id3v2_tag['WCOM'] = "http://www.riaa.org/"
      mp3.id3v2_tag['TXXX'] = "A sample comment"
    end
    
    mp3 = Mp3Info.new(@mp3_filename)
    saved_tag = mp3.id3v2_tag
    
    saved_tag['WCOM'].value.should == "http://www.riaa.org/"
    saved_tag['TXXX'].value.should == "A sample comment"
  end
end
