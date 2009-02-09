$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe Mp3Info, 'when working with its "universal" tag' do
  include Mp3InfoHelper
  
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  it "should be able to repeatably update the universal tag without corrupting it" do
    5.times do
      tag = {"title" => Mp3InfoHelper::TEST_TITLE}
      Mp3Info.open(@mp3_filename) do |mp3|
        tag.each { |k,v| mp3.tag[k] = v }
      end
      
      Mp3Info.open(@mp3_filename) { |m| m.tag }.should == tag
    end
  end
  
  it "should be able to store and retrieve shared information backed by an ID3v2 tag" do
    tag = {}
    %w{comments title artist album}.each { |k| tag[k] = k }
    tag["tracknum"] = 34
    
    Mp3Info.open(@mp3_filename) do |mp3|
      tag.each { |k,v| mp3.tag[k] = v }
    end
    
    w = Mp3Info.open(@mp3_filename) { |m| m.tag }
    w.delete("genre")
    w.delete("genre_s")
    w.should == tag
  end
end
