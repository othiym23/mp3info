$:.unshift("lib/")

require 'mp3info'

describe Mp3Info, "when loading a sample MP3 file" do
  include Mp3InfoHelper

  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should load a valid MP3 file without errors" do
    lambda { Mp3Info.new(@mp3_filename).close }.should_not raise_error(Mp3InfoError)
  end
  
  it "should successfully provide an Mp3Info object when opening a valid MP3 file" do
    Mp3Info.open(@mp3_filename) { |info| info.should be_a(Mp3Info) }
  end
  
  it "should return a string description when opening a valid MP3 file" do
    Mp3Info.open(@mp3_filename) { |info| info.to_s.should be_a(String) }
  end
  
  it "should detect that the sample file contains MPEG 1 audio" do
    Mp3Info.open(@mp3_filename) { |info| info.mpeg_version.should == 1 }
  end
  
  it "should detect that the sample file contains layer 3 audio" do
    Mp3Info.open(@mp3_filename) { |info| info.layer.should == 3 }
  end
  
  it "should detect that the sample file does not contain VBR-encoded audio" do
    Mp3Info.open(@mp3_filename) { |info| info.vbr.should_not be_true }
  end
  
  it "should detect that the sample file has a CBR bitrate of 128kbps" do
    Mp3Info.open(@mp3_filename) { |info| info.bitrate.should == 128 }
  end
  
  it "should detect that the sample file is encoded as joint stereo" do
    Mp3Info.open(@mp3_filename) { |info| info.channel_mode.should == "Joint stereo" }
  end
  
  it "should detect that the sample file has a sample rate of 44.1kHz" do
    Mp3Info.open(@mp3_filename) { |info| info.samplerate.should == 44_100 }
  end
  
  it "should detect that the sample file is not error-protected" do
    Mp3Info.open(@mp3_filename) { |info| info.error_protection.should be_false }
  end
  
  it "should detect that the sample file has a duration of 0.1305625 seconds" do
    Mp3Info.open(@mp3_filename) { |info| info.length.should == 0.1305625 }
  end
  
  it "should correctly format the summary info for the sample file" do
    Mp3Info.open(@mp3_filename) { |info| info.to_s.should == "Time: 0:00        MPEG1.0 Layer 3           [ 128kbps @ 44.1kHz - Joint stereo ]" }
  end
end
