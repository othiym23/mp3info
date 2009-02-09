$:.unshift("lib/")

require 'mp3info'

describe Mp3Info, "when loading an invalid MP3 file" do
  before do
    @mp3_filename = "test_mp3info.mp3"
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should recognize when it's passed total garbage" do
    File.open(@mp3_filename, "w") do |f|
      str = "0" * 32 * 1024
      f.write(str)
    end

    lambda { Mp3Info.new(@mp3_filename) }.should raise_error(Mp3InfoError, "There was no useful metadata in #{@mp3_filename}, are you sure it's an MP3?")
  end
end
