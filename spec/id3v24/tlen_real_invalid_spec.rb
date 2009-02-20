# encoding: utf-8
$:.unshift("lib/")

require 'mp3info'

describe Mp3Info, "when reading a set of excerpted MP3 files with TLEN tags set to 0" do
  it "should display a time of 0 wihout throwing errors for track 17" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/04529116bca3c23601b06c1fda44c5904c2b9537.mp3'))
    @mp3.has_id3v2_tag?.should be_true
    @mp3.id3v2_tag['TLEN'].should_not be_nil
    @mp3.id3v2_tag['TLEN'].value.to_i.should == 0
    @mp3.duration_string.should == "0:00"
    @mp3.id3v2_tag['TPE1'].value.should == "Aphex Twin"
    @mp3.id3v2_tag['TRCK'].value.should == "17/26"
  end

  it "should display a time of 0 wihout throwing errors for track 18" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/01ff478b2c203293e5aec1296a44742cc1f4d026.mp3'))
    @mp3.has_id3v2_tag?.should be_true
    @mp3.id3v2_tag['TLEN'].should_not be_nil
    @mp3.id3v2_tag['TLEN'].value.to_i.should == 0
    @mp3.duration_string.should == "0:00"
    @mp3.id3v2_tag['TPE1'].value.should == "Aphex Twin"
    @mp3.id3v2_tag['TRCK'].value.should == "18/26"
  end

  it "should display a time of 0 wihout throwing errors for track 25" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/169e8b2183a3c7b4873ba2a23254092677fdeed4.mp3'))
    @mp3.has_id3v2_tag?.should be_true
    @mp3.id3v2_tag['TLEN'].should_not be_nil
    @mp3.id3v2_tag['TLEN'].value.to_i.should == 0
    @mp3.duration_string.should == "0:00"
    @mp3.id3v2_tag['TPE1'].value.should == "Aphex Twin"
    @mp3.id3v2_tag['TRCK'].value.should == "25/26"
  end
end
