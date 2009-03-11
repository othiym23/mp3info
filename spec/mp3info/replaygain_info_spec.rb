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

  it "should expose Foobar2k-generated replaygain information, if available" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/b51bc09ef4f8e0a82a4ca0d0781ed0b36bd61f5f.mp3'))
    @mp3.replaygain_info.foobar_replaygain.should_not be_nil
    @mp3.replaygain_info.foobar_replaygain.valid?.should be_true
  end

  it "should expose iTunes Soundcheck information, if available" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/617d88e5f5f95d988cf48bcfba01a810e105882a.mp3'))
    @mp3.replaygain_info.itunes_replaygain.should_not be_nil
  end
  
  it "should expose RVA2 replaygain information, if available" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Replay Gain RVA2/09-1000-8dBlouder-trackonly.mp3'))
    @mp3.replaygain_info.rva2_replaygain.should_not be_nil
  end

  it "should expose XRVA replaygain information, if available" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/4f0071e80b472c67ea4d0e1dfc46c547978d5c09.mp3'))
    @mp3.replaygain_info.xrva_replaygain.should_not be_nil
  end
  
  it "should expose RVAD replaygain information, if available" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/7f97adc6e357e489f4cb621f10e50ac50911967f.mp3'))
    @mp3.replaygain_info.rvad_replaygain.should_not be_nil
  end
  
  it "should pretty-print the replay gain information (with LAME information) in an easy-to-read form" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Wire/Chairs Missing [Japanese version]/Wire - Chairs Missing [Japanese version] - 12 - I Feel Mysterious Today.mp3'))
    @mp3.replaygain_info.to_s.should ==<<-HERE
MP3 replay gain adjustments:

LAME track gain:     -6.4 dB (Set automatically)
LAME MP3 gain:        0.0 dB

      HERE
  end

  it "should pretty-print the replay gain information (with RGAD information) in an easy-to-read form" do
    Mp3Info.open(@mp3_filename) do |mp3|
      @rgad = "\x93\x18\x7c\x3f\x2a\x14\x4c\x14"
      mp3.id3v2_tag['RGAD'] = ID3V24::Frame.create_frame_from_string("RGAD", @rgad)
    end
    
    @mp3 = Mp3Info.new(@mp3_filename)
    @mp3.replaygain_info.to_s.should ==<<-HERE
MP3 replay gain adjustments:

RGAD track gain:     -2.0 dB (user)
RGAD album gain:      2.0 dB (automatic)
RGAD peak amplitude:  0.98 dB

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

  it "should pretty-print the replay gain information (with RVA information) in an easy-to-read form" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/7d4898b04c985c6030ef610e5e95553defa0c2d2.mp3'))
    @mp3.replaygain_info.to_s.should ==<<-HERE
MP3 replay gain adjustments:

RVA adjustment:
  Front right gain:  6.0 dB
  Front left gain:  6.0 dB

    HERE
  end

  it "should pretty-print the replay gain information (with RVAD information) in an easy-to-read form" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/7f97adc6e357e489f4cb621f10e50ac50911967f.mp3'))
    @mp3.replaygain_info.to_s.should ==<<-HERE
MP3 replay gain adjustments:

RVAD adjustment:
  Front right gain:  6.0 dB
  Front left gain:  6.0 dB

    HERE
  end

  it "should pretty-print the replay gain information (with XRVA information) in an easy-to-read form" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/4f0071e80b472c67ea4d0e1dfc46c547978d5c09.mp3'))
    @mp3.replaygain_info.to_s.should ==<<-HERE
MP3 replay gain adjustments:

LAME MP3 gain:        0.0 dB

Foobar 2000 track gain: -2.7 dB (0.5716 peak)
Foobar 2000 track minimum: 136
Foobar 2000 track maximum: 252
Foobar 2000 album gain: -3.6 dB (0.5988 peak)
Foobar 2000 album minimum: 135
Foobar 2000 album maximum: 252
Foobar 2000 mp3gain undo string: "+003,+003,N"

XRVA normalize adjustment:
  Master volume gain:  4.4 dB

    HERE
  end

  it "should pretty-print the replay gain information (with iTunes information) in an easy-to-read form" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/617d88e5f5f95d988cf48bcfba01a810e105882a.mp3'))
    @mp3.replaygain_info.to_s.should ==<<-HERE
MP3 replay gain adjustments:

iTunes adjustment (1.0 milliWatt/dBm basis): -4.7 dB
iTunes adjustment (2.5 milliWatt/dBm basis): -11. dB
iTunes peak volume (should be ~1):            1.0644

      HERE
  end

  it "should pretty-print the replay gain information (with replaygain information) in an easy-to-read form" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/b51bc09ef4f8e0a82a4ca0d0781ed0b36bd61f5f.mp3'))
    @mp3.replaygain_info.to_s.should ==<<-HERE
MP3 replay gain adjustments:

LAME MP3 gain:        0.0 dB

Foobar 2000 track gain: -3.0 dB (0.5256 peak)
Foobar 2000 track minimum: 151
Foobar 2000 track maximum: 233
Foobar 2000 album gain: -2.6 dB (0.5336 peak)
Foobar 2000 album minimum: 137
Foobar 2000 album maximum: 251
Foobar 2000 mp3gain undo string: "+004,+004,N"

      HERE
  end
end

describe Mp3Info, "when exposing replaygain information from a file with an iTunes / Soundcheck iTunNORM comment" do
  it "should gracefully handle the case in which there is no iTunes Soundcheck data available" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Wire/Chairs Missing [Japanese version]/Wire - Chairs Missing [Japanese version] - 12 - I Feel Mysterious Today.mp3'))
    @mp3.replaygain_info.itunes_replaygain.should be_nil
  end
end

describe Mp3Info, "when exposing replaygain information from a file with foobar2k-style user text frames" do
  it "should gracefully handle the case in which there is no textframe-stored replaygain data available" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Wire/Chairs Missing [Japanese version]/Wire - Chairs Missing [Japanese version] - 12 - I Feel Mysterious Today.mp3'))
    @mp3.replaygain_info.foobar_replaygain.valid?.should be_false
  end
end

describe Mp3Info, "when exposing replaygain information from a file with an ID3v2.3.0 XRVA frame from normalize" do
  it "should gracefully handle the case in which there is no XRVA replaygain data available" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Wire/Chairs Missing [Japanese version]/Wire - Chairs Missing [Japanese version] - 12 - I Feel Mysterious Today.mp3'))
    @mp3.replaygain_info.xrva_replaygain.should be_nil
  end
end
