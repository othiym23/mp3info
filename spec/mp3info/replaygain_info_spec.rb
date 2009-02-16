$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe Mp3Info, "when exposing replaygain information" do
  include Mp3InfoHelper
  
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @trivial_rva2_tag = {"RVA2" => ID3V24::RVA2Frame.default(-2.0)}
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should always provide a replaygain information container" do
    Mp3Info.new(@mp3_filename).replaygain_info.should_not be_nil
  end
  
  it "should expose LAME replaygain information, if available" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Wire/Chairs Missing [Japanese version]/Wire - Chairs Missing [Japanese version] - 12 - I Feel Mysterious Today.mp3'))
    @mp3.replaygain_info.lame_replaygain.should_not be_nil
  end
  
  it "should expose LAME mp3 gain information, if available" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Wire/Chairs Missing [Japanese version]/Wire - Chairs Missing [Japanese version] - 12 - I Feel Mysterious Today.mp3'))
    @mp3.replaygain_info.mp3_gain.should_not be_nil
  end
  
  it "should expose RVA2 replaygain information, if available" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Replay Gain RVA2/09-1000-8dBlouder-trackonly.mp3'))
    @mp3.replaygain_info.rva2_replaygain.should_not be_nil
  end
  
  it "should pretty-print the replay gain information (with LAME information) in an easy-to-read form" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Wire/Chairs Missing [Japanese version]/Wire - Chairs Missing [Japanese version] - 12 - I Feel Mysterious Today.mp3'))
    @mp3.replaygain_info.to_s.should ==<<-HERE
MP3 replay gain adjustments:

LAME radio gain:      -6.4 dB (Set automatically)
LAME MP3 gain:         0.0 dB

      HERE
  end

  it "should pretty-print the replay gain information (with RVA2 information) in an easy-to-read form" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Replay Gain RVA2/09-1000-8dBlouder-trackonly.mp3'))
    @mp3.replaygain_info.to_s.should ==<<-HERE
MP3 replay gain adjustments:

RVA2 track adjustment:
  Master volume gain:  8.0 dB (peak gain limit: 6553)

    HERE
  end
end
