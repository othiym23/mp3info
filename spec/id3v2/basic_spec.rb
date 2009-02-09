$:.unshift("lib/")

require 'mp3info/id3v2'

describe ID3V2, "when creating ID3v2 tags" do
  before do
    @tag = ID3V2.new
  end
  
  it "should create a tag that is valid by default" do
    @tag.valid?.should be_true
  end
  
  it "should create a tag with a major version of 4 by default" do
    @tag.major_version.should == 4
  end

  it "should create a tag with a minor version of 0 by default" do
    @tag.minor_version.should == 0
  end

  it "should create a tag with a full version of '2.4.0' by default" do
    @tag.version.should == '2.4.0'
  end
  
  it "should create a tag without unsynchronized frames by default" do
    @tag.unsynchronized?.should be_false
  end
  
  it "should create a tag with no extended header by default" do
    @tag.extended_header?.should be_false
  end
  
  it "should create a tag that are not experimental (as if) by default" do
    @tag.experimental?.should be_false
  end
  
  it "should create a tag that do not have footers by default" do
    @tag.footer?.should be_false
  end
  
  it "should recognize an empty ID3v2.2 tag" do
    tag_string = "ID3\x02\x00\x00\x00\x00\x00\x00"
    @tag.from_bin(tag_string)
    @tag.valid?.should be_true
    @tag.major_version.should == 2
    @tag.minor_version.should == 0
    @tag.version.should == "2.2.0"
  end
end
