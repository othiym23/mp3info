$:.unshift("lib/")

require 'mp3info'

describe Mp3Info, "when reading the MP3 info from an encoding of Keith Fullerton Whitman's 'Stereo Music for Hi-Hat'" do
  before :all do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Keith Fullerton Whitman/Multiples/Stereo Music For Hi-Hat.mp3'))
    @mpeg_info = @mp3.mpeg_header
    @xing_info = @mp3.xing_header
    @lame_info = @mp3.lame_header
  end
  
  it "should verify that the MPEG header exists the same as eyeD3" do
    @mp3.has_mpeg_header?.should be_true
  end
  
  it "should find the MPEG header the same as eyeD3" do
    @mp3.mpeg_header.should_not be_nil
  end
  
  it "should verify that the MPEG is of type 1.0 the same as eyeD3" do
    @mpeg_info.version.should == 1.0
  end
  
  it "should verify that the MPEG is layer 3 the same as eyeD3" do
    @mpeg_info.layer.should == 3
  end
  
  it "should verify that the MPEG has a sample rate of 44.1kHz the same as eyeD3" do
    @mpeg_info.sample_rate.should == 44_100
  end
  
  it "should verify that the MPEG header claims a bitrate of 128kbps the same as eyeD3" do
    @mpeg_info.bitrate.should == 128
  end
  
  it "should verify that the MPEG is joint stereo the same as eyeD3" do
    @mpeg_info.mode.should == 'Joint stereo'
  end
  
  it "should verify that the MPEG has no mode extension the same as eyeD3" do
    @mpeg_info.mode_extension.should == 0
  end
  
  it "should verify that the MPEG is not error protected the same as eyeD3" do
    @mpeg_info.error_protection.should be_false
  end
  
  it "should verify that the MPEG is an original stream the same as eyeD3" do
    @mpeg_info.original_stream?.should be_true
  end
  
  it "should verify that the MPEG is not copyrighted the same as eyeD3" do
    @mpeg_info.copyrighted_stream?.should be_false
  end
  
  it "should verify that the MPEG is not a private stream the same as eyeD3" do
    @mpeg_info.private_stream?.should be_false
  end
  
  it "should verify that the MPEG is not a padded stream the same as eyeD3" do
    @mpeg_info.padded_stream?.should be_false
  end
  
  it "should verify that the MPEG has no emphasis the same as eyeD3" do
    @mpeg_info.emphasis.should == MPEGHeader::EMPHASIS_NONE
  end
  
  it "should verify that the MPEG has a frame length of 417 the same as eyeD3" do
    @mpeg_info.frame_length.should == 417
  end
  
  it "should verify that the Xing header exists the same as eyeD3" do
    @mp3.has_xing_header?.should be_true
  end
  
  it "should verify that there is a Xing header the same as eyeD3" do
    @mp3.xing_header.should_not be_nil
  end
  
  it "should verify that the Xing header says the stream is VBR the same as eyeD3" do
    @xing_info.vbr?.should be_true
  end
  
  it "should verify that the Xing header says there are 6,493 frames the same as eyeD3" do
    @xing_info.frames.should == 6_493
  end
  
  it "should verify that the Xing header says there are 3,539,892 bytes in the stream the same as eyeD3" do
    @xing_info.bytes.should == 3_539_892
  end
  
  it "should verify that the Xing header contains a table of contents the same as eyeD3" do
    @xing_info.has_toc?.should be_true
  end
  
  it "should verify that the Xing header says the stream has a quality of 57 the same as eyeD3" do
    @xing_info.quality.should == 57
  end
  
  it "should verify that the LAME tag exists the same as eyeD3" do
    @mp3.has_lame_header?.should be_true
  end
  
  it "should verify that there is a LAME tag the same as eyeD3" do
    @mp3.lame_header.should_not be_nil
  end
  
  it "should verify that the LAME tag has a valid header is valid the same as eyeD3" do
    @lame_info.valid_header?.should be_true
  end
  
  it "should verify that the LAME tag has a valid CRC the same as eyeD3" do
    @lame_info.valid_crc?.should be_true
  end
  
  it "should verify that the LAME tag is valid the same as eyeD3" do
    @lame_info.valid?.should be_true
  end
  
  it "should verify that the version of LAME used was 3.94a the same as eyeD3" do
    @lame_info.encoder_version.should == "LAME3.94a"
  end
  
  it "should verify that the LAME tag version is 0 the same as eyeD3" do
    @lame_info.tag_version.should == 0
  end
  
  it "should verify that the LAME VBR method was old/rh the same as eyeD3" do
    @lame_info.vbr_method.should == 'Variable Bitrate method1 (old/rh)'
  end
  
  it "should verify that the LAME lowpass frequency was 19kHz the same as eyeD3" do
    @lame_info.lowpass_filter.should == 19_000
  end
  
  it "should verify that the LAME tag has encoder flags the same as eyeD3" do
    @lame_info.encoder_flags.should_not be_empty
  end
  
  it "should verify that the LAME encoder flags were NSPSYTUNE and NSSAFEJOINT the same as eyeD3" do
    @lame_info.encoder_flag_string.should == '--nspsytune --nssafejoint'
  end
  
  it "should verify that the LAME tag has no gapless encoding flags the same as eyeD3" do
    @lame_info.nogap_flags.should be_empty
  end
  
  it "should verify that the LAME gapless flag string is empty the same as eyeD3" do
    @lame_info.nogap_flag_string.should == ''
  end
  
  it "should verify that the LAME tag indicates an ATH type of 4 the same as eyeD3" do
    @lame_info.ath_type.should == 4
  end
  
  it "should verify that the LAME tag's CRC is 0x4446 the same as eyeD3" do
    @lame_info.lame_tag_crc.should == 0x4446
  end
  
  it "should verify that there is no bitrate in the LAME tag the same as eyeD3" do
    @lame_info.bitrate.should == 0
  end
  
  it "should verify that the bitrate type is 'Minimum' the same as eyeD3" do
    @lame_info.bitrate_type.should == 'Minimum'
  end
  
  it "should verify that the LAME encoding has a delay of 576 samples the same as eyeD3" do
    @lame_info.encoder_delay.should == 576
  end
  
  it "should verify that the LAME padding of 1,788 byte the same as eyeD3" do
    @lame_info.encoder_padding.should == 1_788
  end
  
  it "should verify that the LAME encoding has a noise shaping curve of type 1 the same as eyeD3" do
    @lame_info.noise_shaping_type.should == 1
  end
  
  it "should verify that the LAME sample frequency is set to 44.1kHz the same as eyeD3" do
    @lame_info.sample_frequency.should == '44.1 kHz'
  end
  
  it "should verify that LAME's settings were not unwise the same as eyeD3" do
    @lame_info.unwise_settings?.should be_false
  end
  
  it "should verify that the LAME stereo mode was 'Joint' the same as eyeD3" do
    @lame_info.stereo_mode.should == 'Joint'
  end
  
  it "should verify that the LAME tag has an MP3 gain of 0 the same as eyeD3" do
    @lame_info.mp3_gain.should == 0
  end
  
  it "should verify that the LAME tag has an MP3 gain of 0dB the same as eyeD3" do
    @lame_info.mp3_gain_db.should == 0.0
  end
  
  it "should verify that the LAME tag has no surround sound info the same as eyeD3" do
    @lame_info.surround_info.should == 'None'
  end
  
  it "should verify that the LAME preset was standard the same as eyeD3" do
    @lame_info.preset.should == 'standard'
  end
  
  it "should verify that the LAME tag indicates the music length is 3,539,892 bytes the same as eyeD3" do
    @lame_info.music_length.should == 3_539_892
  end
  
  it "should verify that the LAME music CRC is 0x1F4E the same as eyeD3" do
    @lame_info.music_crc.should == 0x1F4E
  end
  
  it "should verify that the LAME tag has replaygain info the same as eyeD3" do
    @lame_info.replay_gain.should_not be_nil
  end
  
  it "should verify that the LAME tag has no replaygain peak RMS the same as eyeD3" do
    @lame_info.replay_gain.peak.should be_nil
  end
  
  it "should verify that the LAME tag has no replaygain dB the same as eyeD3" do
    @lame_info.replay_gain.db.should be_nil
  end
  
  it "should verify that the LAME replaygain tag has radio info the same as eyeD3" do
    @lame_info.replay_gain.radio.should_not be_nil
  end
  
  it "should verify that the LAME replaygain radio info is set the same as eyeD3" do
    @lame_info.replay_gain.radio.set?.should be_true
  end
  
  it "should verify that the LAME replaygain radio info has a name of 'Radio' the same as eyeD3" do
    @lame_info.replay_gain.radio.name.should == 'Radio'
  end
  
  it "should verify that the LAME replaygain radio info has an originator of 'Set automatically' the same as eyeD3" do
    @lame_info.replay_gain.radio.originator.should == 'Set automatically'
  end
  
  it "should verify that the LAME replaygain radio info has an adjustment of -4.2 the same as eyeD3" do
    @lame_info.replay_gain.radio.adjustment.should == -4.2
  end
  
  it "should verify that the LAME replaygain radio info has a certain format the same as eyeD3" do
    @lame_info.replay_gain.radio.to_s.should == 'Radio Replay Gain: -4.2 dB (Set automatically)'
  end
  
  it "should verify that the LAME replaygain tag has audiofile info the same as eyeD3" do
    @lame_info.replay_gain.audiofile.should_not be_nil
  end
  
  it "should verify that the LAME replaygain audiofile info is not set the same as eyeD3" do
    @lame_info.replay_gain.audiofile.set?.should be_false
  end
end

describe Mp3Info, "when reading the MP3 info from an encoding of RAC's 'Distance [remake]'" do
  before :all do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/RAC/Double Jointed/02 - RAC - Distance _Remake_.mp3'))
    @mpeg_info = @mp3.mpeg_header
    @xing_info = @mp3.xing_header
    @lame_info = @mp3.lame_header
  end
  
  it "should verify that the MPEG header exists the same as eyeD3" do
    @mp3.has_mpeg_header?.should be_true
  end
  
  it "should find the MPEG header the same as eyeD3" do
    @mp3.mpeg_header.should_not be_nil
  end
  
  it "should verify that the MPEG is of type 1.0 the same as eyeD3" do
    @mpeg_info.version.should == 1.0
  end
  
  it "should verify that the MPEG is layer 3 the same as eyeD3" do
    @mpeg_info.layer.should == 3
  end
  
  it "should verify that the MPEG has a sample rate of 44.1kHz the same as eyeD3" do
    @mpeg_info.sample_rate.should == 44_100
  end
  
  it "should verify that the MPEG header claims a bitrate of 128kbps the same as eyeD3" do
    @mpeg_info.bitrate.should == 128
  end
  
  it "should verify that the MPEG is joint stereo the same as eyeD3" do
    @mpeg_info.mode.should == 'Joint stereo'
  end
  
  it "should verify that the MPEG has a mode extension of M/S stereo the same as eyeD3" do
    @mpeg_info.mode_extension.should == MPEGHeader::MODE_EXTENSION_M_S_STEREO
  end
  
  it "should verify that the MPEG is not error protected the same as eyeD3" do
    @mpeg_info.error_protection.should be_false
  end
  
  it "should verify that the MPEG is an original stream the same as eyeD3" do
    @mpeg_info.original_stream?.should be_true
  end
  
  it "should verify that the MPEG is not copyrighted the same as eyeD3" do
    @mpeg_info.copyrighted_stream?.should be_false
  end
  
  it "should verify that the MPEG is not a private stream the same as eyeD3" do
    @mpeg_info.private_stream?.should be_false
  end
  
  it "should verify that the MPEG is not a padded stream the same as eyeD3" do
    @mpeg_info.padded_stream?.should be_false
  end
  
  it "should verify that the MPEG has no emphasis the same as eyeD3" do
    @mpeg_info.emphasis.should == MPEGHeader::EMPHASIS_NONE
  end
  
  it "should verify that the MPEG has a frame length of 417 the same as eyeD3" do
    @mpeg_info.frame_length.should == 417
  end
  
  it "should verify that the Xing header exists the same as eyeD3" do
    @mp3.has_xing_header?.should be_true
  end
  
  it "should verify that there is a Xing header the same as eyeD3" do
    @mp3.xing_header.should_not be_nil
  end
  
  it "should verify that the Xing header says the stream is VBR the same as eyeD3" do
    @xing_info.vbr?.should be_true
  end
  
  it "should verify that the Xing header says there are 12,900 frames the same as eyeD3" do
    @xing_info.frames.should == 12_900
  end
  
  it "should verify that the Xing header says there are 9,457,829 bytes in the stream the same as eyeD3" do
    @xing_info.bytes.should == 9_457_829
  end
  
  it "should verify that the Xing header contains a table of contents the same as eyeD3" do
    @xing_info.has_toc?.should be_true
  end
  
  it "should verify that the Xing header says the stream has a quality of 78 the same as eyeD3" do
    @xing_info.quality.should == 78
  end
  
  it "should verify that the LAME tag exists the same as eyeD3" do
    @mp3.has_lame_header?.should be_true
  end
  
  it "should verify that there is a LAME tag the same as eyeD3" do
    @mp3.lame_header.should_not be_nil
  end
  
  it "should verify that the LAME tag has a valid header is valid the same as eyeD3" do
    @lame_info.valid_header?.should be_true
  end
  
  it "should verify that the LAME tag has a valid CRC the same as eyeD3" do
    @lame_info.valid_crc?.should be_true
  end
  
  it "should verify that the LAME tag is valid the same as eyeD3" do
    @lame_info.valid?.should be_true
  end
  
  it "should verify that the version of LAME used was 3.90.(3) the same as eyeD3" do
    @lame_info.encoder_version.should == "LAME3.90."
  end
  
  it "should verify that the LAME tag version is 0 the same as eyeD3" do
    @lame_info.tag_version.should == 0
  end
  
  it "should verify that the LAME VBR method was old/rh the same as eyeD3" do
    @lame_info.vbr_method.should == 'Variable Bitrate method1 (old/rh)'
  end
  
  it "should verify that the LAME lowpass frequency was 19kHz the same as eyeD3" do
    @lame_info.lowpass_filter.should == 19_000
  end
  
  it "should verify that the LAME tag has encoder flags the same as eyeD3" do
    @lame_info.encoder_flags.should_not be_empty
  end
  
  it "should verify that the LAME encoder flags were NSPSYTUNE and NSSAFEJOINT the same as eyeD3" do
    @lame_info.encoder_flag_string.should == '--nspsytune --nssafejoint'
  end
  
  it "should verify that the LAME tag has no gapless encoding flags the same as eyeD3" do
    @lame_info.nogap_flags.should be_empty
  end
  
  it "should verify that the LAME gapless flag string is empty the same as eyeD3" do
    @lame_info.nogap_flag_string.should == ''
  end
  
  it "should verify that the LAME tag indicates an ATH type of 4 the same as eyeD3" do
    @lame_info.ath_type.should == 4
  end
  
  it "should verify that the LAME tag's CRC is 0x4446 the same as eyeD3" do
    @lame_info.lame_tag_crc.should == 0x84D9
  end
  
  it "should verify that the guaranteed minimum bitrate in the LAME tag is 192 the same as eyeD3" do
    @lame_info.bitrate.should == 192
  end
  
  it "should verify that the bitrate type is 'Minimum' the same as eyeD3" do
    @lame_info.bitrate_type.should == 'Minimum'
  end
  
  it "should verify that the LAME encoding has a delay of 576 samples the same as eyeD3" do
    @lame_info.encoder_delay.should == 576
  end
  
  it "should verify that the LAME padding of 1,464 byte the same as eyeD3" do
    @lame_info.encoder_padding.should == 1_464
  end
  
  it "should verify that the LAME encoding has a noise shaping curve of type 1 the same as eyeD3" do
    @lame_info.noise_shaping_type.should == 1
  end
  
  it "should verify that the LAME sample frequency is set to 44.1kHz the same as eyeD3" do
    @lame_info.sample_frequency.should == '44.1 kHz'
  end
  
  it "should verify that LAME's settings were not unwise the same as eyeD3" do
    @lame_info.unwise_settings?.should be_false
  end
  
  it "should verify that the LAME stereo mode was 'Joint' the same as eyeD3" do
    @lame_info.stereo_mode.should == 'Joint'
  end
  
  it "should verify that the LAME tag has an MP3 gain of 0 the same as eyeD3" do
    @lame_info.mp3_gain.should == 0
  end
  
  it "should verify that the LAME tag has an MP3 gain of 0dB the same as eyeD3" do
    @lame_info.mp3_gain_db.should == 0.0
  end
  
  it "should verify that the LAME tag has no surround sound info the same as eyeD3" do
    @lame_info.surround_info.should == 'None'
  end
  
  it "should verify that the LAME preset was unknown (actually alt-preset standard) the same as eyeD3" do
    @lame_info.preset.should == 'Unknown'
  end
  
  it "should verify that the LAME tag indicates the music length is 9,457,829 bytes the same as eyeD3" do
    @lame_info.music_length.should == 9_457_829
  end
  
  it "should verify that the LAME music CRC is 0xFBD3 the same as eyeD3" do
    @lame_info.music_crc.should == 0xFBD3
  end
  
  it "should verify that the LAME tag has replaygain info the same as eyeD3" do
    @lame_info.replay_gain.should_not be_nil
  end
  
  it "should verify that the LAME tag has no replaygain peak RMS the same as eyeD3" do
    @lame_info.replay_gain.peak.should be_nil
  end
  
  it "should verify that the LAME tag has no replaygain dB the same as eyeD3" do
    @lame_info.replay_gain.db.should be_nil
  end
  
  it "should verify that the LAME replaygain tag has radio info the same as eyeD3" do
    @lame_info.replay_gain.radio.should_not be_nil
  end
  
  it "should verify that the LAME replaygain radio info is not set the same as eyeD3" do
    @lame_info.replay_gain.radio.set?.should be_false
  end
  
  it "should verify that the LAME replaygain tag has audiofile info the same as eyeD3" do
    @lame_info.replay_gain.audiofile.set?.should be_false
  end
end

describe Mp3Info, "when reading the MP3 info from an encoding of Wire's 'I Feel Mysterious Today'" do
  before :all do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Wire/Chairs Missing [Japanese version]/Wire - Chairs Missing [Japanese version] - 12 - I Feel Mysterious Today.mp3'))
    @mpeg_info = @mp3.mpeg_header
    @xing_info = @mp3.xing_header
    @lame_info = @mp3.lame_header
  end
  
  it "should verify that the MPEG header exists the same as eyeD3" do
    @mp3.has_mpeg_header?.should be_true
  end
  
  it "should find the MPEG header the same as eyeD3" do
    @mp3.mpeg_header.should_not be_nil
  end
  
  it "should verify that the MPEG is of type 1.0 the same as eyeD3" do
    @mpeg_info.version.should == 1.0
  end
  
  it "should verify that the MPEG is layer 3 the same as eyeD3" do
    @mpeg_info.layer.should == 3
  end
  
  it "should verify that the MPEG has a sample rate of 44.1kHz the same as eyeD3" do
    @mpeg_info.sample_rate.should == 44_100
  end
  
  it "should verify that the MPEG header claims a bitrate of 128kbps the same as eyeD3" do
    @mpeg_info.bitrate.should == 128
  end
  
  it "should verify that the MPEG is joint stereo the same as eyeD3" do
    @mpeg_info.mode.should == 'Joint stereo'
  end
  
  it "should verify that the MPEG has no mode extension the same as eyeD3" do
    @mpeg_info.mode_extension.should == 0 # none
  end
  
  it "should verify that the MPEG is not error protected the same as eyeD3" do
    @mpeg_info.error_protection.should be_false
  end
  
  it "should verify that the MPEG is an original stream the same as eyeD3" do
    @mpeg_info.original_stream?.should be_true
  end
  
  it "should verify that the MPEG is not copyrighted the same as eyeD3" do
    @mpeg_info.copyrighted_stream?.should be_false
  end
  
  it "should verify that the MPEG is not a private stream the same as eyeD3" do
    @mpeg_info.private_stream?.should be_false
  end
  
  it "should verify that the MPEG is not a padded stream the same as eyeD3" do
    @mpeg_info.padded_stream?.should be_false
  end
  
  it "should verify that the MPEG has no emphasis the same as eyeD3" do
    @mpeg_info.emphasis.should == MPEGHeader::EMPHASIS_NONE
  end
  
  it "should verify that the MPEG has a frame length of 417 the same as eyeD3" do
    @mpeg_info.frame_length.should == 417
  end
  
  it "should verify that the Xing header exists the same as eyeD3" do
    @mp3.has_xing_header?.should be_true
  end
  
  it "should verify that there is a Xing header the same as eyeD3" do
    @mp3.xing_header.should_not be_nil
  end
  
  it "should verify that the Xing header says the stream is VBR the same as eyeD3" do
    @xing_info.vbr?.should be_true
  end
  
  it "should verify that the Xing header says there are 4,432 frames the same as eyeD3" do
    @xing_info.frames.should == 4_432
  end
  
  it "should verify that the Xing header says there are 2,963,271 bytes in the stream the same as eyeD3" do
    @xing_info.bytes.should == 2_963_271
  end
  
  it "should verify that the Xing header contains a table of contents the same as eyeD3" do
    @xing_info.has_toc?.should be_true
  end
  
  it "should verify that the Xing header says the stream has a quality of 57 the same as eyeD3" do
    @xing_info.quality.should == 77
  end
  
  it "should verify that the LAME tag exists the same as eyeD3" do
    @mp3.has_lame_header?.should be_true
  end
  
  it "should verify that there is a LAME tag the same as eyeD3" do
    @mp3.lame_header.should_not be_nil
  end
  
  it "should verify that the LAME tag has a valid header is valid the same as eyeD3" do
    @lame_info.valid_header?.should be_true
  end
  
  it "should verify that the LAME tag has a valid CRC the same as eyeD3" do
    @lame_info.valid_crc?.should be_true
  end
  
  it "should verify that the LAME tag is valid the same as eyeD3" do
    @lame_info.valid?.should be_true
  end
  
  it "should verify that the version of LAME used was 3.94a the same as eyeD3" do
    @lame_info.encoder_version.should == "LAME3.96r"
  end
  
  it "should verify that the LAME tag version is 0 the same as eyeD3" do
    @lame_info.tag_version.should == 0
  end
  
  it "should verify that the LAME VBR method was old/rh the same as eyeD3" do
    @lame_info.vbr_method.should == 'Variable Bitrate method1 (old/rh)'
  end
  
  it "should verify that the LAME lowpass frequency was 19kHz the same as eyeD3" do
    @lame_info.lowpass_filter.should == 19_000
  end
  
  it "should verify that the LAME tag has encoder flags the same as eyeD3" do
    @lame_info.encoder_flags.should_not be_empty
  end
  
  it "should verify that the LAME encoder flags were NSPSYTUNE and NSSAFEJOINT the same as eyeD3" do
    @lame_info.encoder_flag_string.should == '--nspsytune --nssafejoint'
  end
  
  it "should verify that the LAME tag has no gapless encoding flags the same as eyeD3" do
    @lame_info.nogap_flags.should be_empty
  end
  
  it "should verify that the LAME gapless flag string is empty the same as eyeD3" do
    @lame_info.nogap_flag_string.should == ''
  end
  
  it "should verify that the LAME tag indicates an ATH type of 4 the same as eyeD3" do
    @lame_info.ath_type.should == 4
  end
  
  it "should verify that the LAME tag's CRC is 0xD487 the same as eyeD3" do
    @lame_info.lame_tag_crc.should == 0xD487
  end
  
  it "should verify that bitrate in the LAME tag is set to 128kbps the same as eyeD3" do
    @lame_info.bitrate.should == 128
  end
  
  it "should verify that the bitrate type is 'Minimum' the same as eyeD3" do
    @lame_info.bitrate_type.should == 'Minimum'
  end
  
  it "should verify that the LAME encoding has a delay of 576 samples the same as eyeD3" do
    @lame_info.encoder_delay.should == 576
  end
  
  it "should verify that the LAME padding of 1,344 bytes the same as eyeD3" do
    @lame_info.encoder_padding.should == 1_344
  end
  
  it "should verify that the LAME encoding has a noise shaping curve of type 1 the same as eyeD3" do
    @lame_info.noise_shaping_type.should == 1
  end
  
  it "should verify that the LAME sample frequency is set to 44.1kHz the same as eyeD3" do
    @lame_info.sample_frequency.should == '44.1 kHz'
  end
  
  it "should verify that LAME's settings were not unwise the same as eyeD3" do
    @lame_info.unwise_settings?.should be_false
  end
  
  it "should verify that the LAME stereo mode was 'Joint' the same as eyeD3" do
    @lame_info.stereo_mode.should == 'Joint'
  end
  
  it "should verify that the LAME tag has an MP3 gain of 0 the same as eyeD3" do
    @lame_info.mp3_gain.should == 0
  end
  
  it "should verify that the LAME tag has an MP3 gain of 0dB the same as eyeD3" do
    @lame_info.mp3_gain_db.should == 0.0
  end
  
  it "should verify that the LAME tag has no surround sound info the same as eyeD3" do
    @lame_info.surround_info.should == 'None'
  end
  
  it "should verify that the LAME preset was -V2 the same as eyeD3" do
    @lame_info.preset.should == 'V2'
  end
  
  it "should verify that the LAME tag indicates the music length is 2,963,271 bytes the same as eyeD3" do
    @lame_info.music_length.should == 2_963_271
  end
  
  it "should verify that the LAME music CRC is 0xF82D the same as eyeD3" do
    @lame_info.music_crc.should == 0xF82D
  end
  
  it "should verify that the LAME tag has replaygain info the same as eyeD3" do
    @lame_info.replay_gain.should_not be_nil
  end
  
  it "should verify that the LAME tag has no replaygain peak RMS the same as eyeD3" do
    @lame_info.replay_gain.peak.should be_nil
  end
  
  it "should verify that the LAME tag has no replaygain dB the same as eyeD3" do
    @lame_info.replay_gain.db.should be_nil
  end
  
  it "should verify that the LAME replaygain tag has radio info the same as eyeD3" do
    @lame_info.replay_gain.radio.should_not be_nil
  end
  
  it "should verify that the LAME replaygain radio info is set the same as eyeD3" do
    @lame_info.replay_gain.radio.set?.should be_true
  end
  
  it "should verify that the LAME replaygain radio info has a name of 'Radio' the same as eyeD3" do
    @lame_info.replay_gain.radio.name.should == 'Radio'
  end
  
  it "should verify that the LAME replaygain radio info has an originator of 'Set automatically' the same as eyeD3" do
    @lame_info.replay_gain.radio.originator.should == 'Set automatically'
  end
  
  it "should verify that the LAME replaygain radio info has an adjustment of -6.4 the same as eyeD3" do
    @lame_info.replay_gain.radio.adjustment.should == -6.4
  end
  
  it "should verify that the LAME replaygain radio info has a certain format the same as eyeD3" do
    @lame_info.replay_gain.radio.to_s.should == 'Radio Replay Gain: -6.4 dB (Set automatically)'
  end
  
  it "should verify that the LAME replaygain tag has audiofile info the same as eyeD3" do
    @lame_info.replay_gain.audiofile.should_not be_nil
  end
  
  it "should verify that the LAME replaygain audiofile info is not set the same as eyeD3" do
    @lame_info.replay_gain.audiofile.set?.should be_false
  end
end

describe Mp3Info, "when reading the MP3 info from an encoding of Jürgen Paape's 'Fruity Loops 1'" do
  before :all do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Jurgen Paape/Speicher 47/01 Fruity Loops 1.mp3'))
    @mpeg_info = @mp3.mpeg_header
  end
  
  it "should verify that the MPEG header exists the same as eyeD3" do
    @mp3.has_mpeg_header?.should be_true
  end
  
  it "should find the MPEG header the same as eyeD3" do
    @mp3.mpeg_header.should_not be_nil
  end
  
  it "should verify that the MPEG is of type 1.0 the same as eyeD3" do
    @mpeg_info.version.should == 1.0
  end
  
  it "should verify that the MPEG is layer 3 the same as eyeD3" do
    @mpeg_info.layer.should == 3
  end
  
  it "should verify that the MPEG has a sample rate of 44.1kHz the same as eyeD3" do
    @mpeg_info.sample_rate.should == 44_100
  end
  
  it "should verify that the MPEG header claims a bitrate of 128kbps the same as eyeD3" do
    @mpeg_info.bitrate.should == 320
  end
  
  it "should verify that the MPEG is joint stereo the same as eyeD3" do
    @mpeg_info.mode.should == 'Joint stereo'
  end
  
  it "should verify that the MPEG has no mode extension the same as eyeD3" do
    @mpeg_info.mode_extension.should == 0
  end
  
  it "should verify that the MPEG is not error protected the same as eyeD3" do
    @mpeg_info.error_protection.should be_false
  end
  
  it "should verify that the MPEG is an original stream the same as eyeD3" do
    @mpeg_info.original_stream?.should be_true
  end
  
  it "should verify that the MPEG is not copyrighted the same as eyeD3" do
    @mpeg_info.copyrighted_stream?.should be_false
  end
  
  it "should verify that the MPEG is not a private stream the same as eyeD3" do
    @mpeg_info.private_stream?.should be_false
  end
  
  it "should verify that the MPEG is not a padded stream the same as eyeD3" do
    @mpeg_info.padded_stream?.should be_false
  end
  
  it "should verify that the MPEG has no emphasis the same as eyeD3" do
    @mpeg_info.emphasis.should == MPEGHeader::EMPHASIS_NONE
  end
  
  it "should verify that the MPEG has a frame length of 1,044 the same as eyeD3" do
    @mpeg_info.frame_length.should == 1_044
  end
  
  it "should verify that the Xing header doesn't exist the same as eyeD3" do
    @mp3.has_xing_header?.should be_false
  end
  
  it "should verify that there is no Xing header the same as eyeD3" do
    @mp3.xing_header.should be_nil
  end
  
  it "should verify that the LAME tag doesn't exit the same as eyeD3" do
    @mp3.has_lame_header?.should be_false
  end
  
  it "should verify that there is no LAME tag the same as eyeD3" do
    @mp3.lame_header.should be_nil
  end
end