# encoding: utf-8

require 'mp3info'

describe Mp3Info, "when reading the MP3 info from an encoding of Keith Fullerton Whitman's 'Stereo Music for Hi-Hat'" do
  before :all do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Keith Fullerton Whitman/Multiples/Stereo Music For Hi-Hat.mp3'))
    @mpeg_info = @mp3.mpeg_header
    @xing_info = @mp3.xing_header
    @lame_info = @mp3.lame_header
  end
  
  it "should verify that the MPEG header exists" do
    expect(@mp3.has_mpeg_header?).to be true
  end
  
  it "should find the MPEG header" do
    expect(@mp3.mpeg_header).not_to be_nil
  end
  
  it "should verify that the MPEG is of type 1.0" do
    expect(@mpeg_info.version).to eq(1.0)
  end
  
  it "should verify that the MPEG is layer 3" do
    expect(@mpeg_info.layer).to eq(3)
  end
  
  it "should verify that the MPEG has a sample rate of 44.1kHz" do
    expect(@mpeg_info.sample_rate).to eq(44_100)
  end
  
  it "should verify that the MPEG header claims a bitrate of 128kbps" do
    expect(@mpeg_info.bitrate).to eq(128)
  end
  
  it "should verify that the MPEG is joint stereo" do
    expect(@mpeg_info.mode).to eq('Joint stereo')
  end
  
  it "should verify that the MPEG has no mode extension" do
    expect(@mpeg_info.mode_extension).to eq(0)
  end
  
  it "should verify that the MPEG is not error protected" do
    expect(@mpeg_info.error_protected?).to be false
  end
  
  it "should verify that the MPEG is an original stream" do
    expect(@mpeg_info.original_stream?).to be true
  end
  
  it "should verify that the MPEG is not copyrighted" do
    expect(@mpeg_info.copyrighted_stream?).to be false
  end
  
  it "should verify that the MPEG is not a private stream" do
    expect(@mpeg_info.private_stream?).to be false
  end
  
  it "should verify that the MPEG is not a padded stream" do
    expect(@mpeg_info.padded_stream?).to be false
  end
  
  it "should verify that the MPEG has no emphasis" do
    expect(@mpeg_info.emphasis).to eq(MPEGHeader::EMPHASIS_NONE)
  end
  
  it "should verify that the MPEG has a frame length of 417" do
    expect(@mpeg_info.frame_size).to eq(417)
  end
  
  it "should verify that the Xing header exists" do
    expect(@mp3.has_xing_header?).to be true
  end
  
  it "should verify that there is a Xing header" do
    expect(@mp3.xing_header).not_to be_nil
  end
  
  it "should verify that the Xing header says the stream is VBR" do
    expect(@xing_info.vbr?).to be true
  end
  
  it "should verify that the Xing header says there are 6,493 frames" do
    expect(@xing_info.frames).to eq(6_493)
  end
  
  it "should verify that the Xing header says there are 3,539,892 bytes in the stream" do
    expect(@xing_info.bytes).to eq(3_539_892)
  end
  
  it "should verify that the Xing header contains a table of contents" do
    expect(@xing_info.has_toc?).to be true
  end
  
  it "should verify that the Xing header says the stream has a quality of 57" do
    expect(@xing_info.quality).to eq(57)
  end
  
  it "should verify that the LAME tag exists" do
    expect(@mp3.has_lame_header?).to be true
  end
  
  it "should verify that there is a LAME tag" do
    expect(@mp3.lame_header).not_to be_nil
  end
  
  it "should verify that the LAME tag has a valid header is valid" do
    expect(@lame_info.valid_header?).to be true
  end
  
  it "should verify that the LAME tag has a valid CRC" do
    expect(@lame_info.valid_crc?).to be true
  end
  
  it "should verify that the LAME tag is valid" do
    expect(@lame_info.valid?).to be true
  end
  
  it "should verify that the version of LAME used was 3.94a" do
    expect(@lame_info.encoder_version).to eq("LAME3.94a")
  end
  
  it "should verify that the LAME tag version is 0" do
    expect(@lame_info.tag_version).to eq(0)
  end
  
  it "should verify that the LAME VBR method was old/rh" do
    expect(@lame_info.vbr_method).to eq('Variable Bitrate method1 (old/rh)')
  end
  
  it "should verify that the LAME lowpass frequency was 19kHz" do
    expect(@lame_info.lowpass_filter).to eq(19_000)
  end
  
  it "should verify that the LAME tag has encoder flags" do
    expect(@lame_info.encoder_flags).not_to be_empty
  end
  
  it "should verify that the LAME encoder flags were NSPSYTUNE and NSSAFEJOINT" do
    expect(@lame_info.encoder_flag_string).to eq('--nspsytune --nssafejoint')
  end
  
  it "should verify that the LAME tag has no gapless encoding flags" do
    expect(@lame_info.nogap_flags).to be_empty
  end
  
  it "should verify that the LAME gapless flag string is empty" do
    expect(@lame_info.nogap_flag_string).to eq('')
  end
  
  it "should verify that the LAME tag indicates an ATH type of 4" do
    expect(@lame_info.ath_type).to eq(4)
  end
  
  it "should verify that the LAME tag's CRC is 0x4446" do
    expect(@lame_info.lame_tag_crc).to eq(0x4446)
  end
  
  it "should verify that there is no bitrate in the LAME tag" do
    expect(@lame_info.bitrate).to eq(0)
  end
  
  it "should verify that the bitrate type is 'Minimum'" do
    expect(@lame_info.bitrate_type).to eq('Minimum')
  end
  
  it "should verify that the LAME encoding has a delay of 576 samples" do
    expect(@lame_info.encoder_delay).to eq(576)
  end
  
  it "should verify that the LAME padding of 1,788 byte" do
    expect(@lame_info.encoder_padding).to eq(1_788)
  end
  
  it "should verify that the LAME encoding has a noise shaping curve of type 1" do
    expect(@lame_info.noise_shaping_type).to eq(1)
  end
  
  it "should verify that the LAME sample frequency is set to 44.1kHz" do
    expect(@lame_info.sample_frequency).to eq('44.1 kHz')
  end
  
  it "should verify that LAME's settings were not unwise" do
    expect(@lame_info.unwise_settings?).to be false
  end
  
  it "should verify that the LAME stereo mode was 'Joint'" do
    expect(@lame_info.stereo_mode).to eq('Joint')
  end
  
  it "should verify that the LAME tag has an MP3 gain of 0" do
    expect(@lame_info.mp3_gain).to eq(0)
  end
  
  it "should verify that the LAME tag has an MP3 gain of 0dB" do
    expect(@lame_info.mp3_gain_db).to eq(0.0)
  end
  
  it "should verify that the LAME tag has no surround sound info" do
    expect(@lame_info.surround_info).to eq('None')
  end
  
  it "should verify that the LAME preset was standard" do
    expect(@lame_info.preset).to eq('standard')
  end
  
  it "should verify that the LAME tag indicates the music length is 3,539,892 bytes" do
    expect(@lame_info.music_length).to eq(3_539_892)
  end
  
  it "should verify that the LAME music CRC is 0x1F4E" do
    expect(@lame_info.music_crc).to eq(0x1F4E)
  end
  
  it "should verify that the LAME tag has replaygain info" do
    expect(@lame_info.replay_gain).not_to be_nil
  end
  
  it "should verify that the LAME tag has no replaygain peak RMS" do
    expect(@lame_info.replay_gain.peak).to be_nil
  end
  
  it "should verify that the LAME tag has no replaygain dB" do
    expect(@lame_info.replay_gain.db).to be_nil
  end
  
  it "should verify that the LAME replaygain tag has track gain" do
    expect(@lame_info.replay_gain.track_gain).not_to be_nil
  end
  
  it "should verify that the LAME replaygain track gain info is set" do
    expect(@lame_info.replay_gain.track_gain.set?).to be true
  end
  
  it "should verify that the LAME replaygain track gain info has a name of 'Track' instead of eyeD3's 'Radio'" do
    expect(@lame_info.replay_gain.track_gain.type).to eq('Track')
  end
  
  it "should verify that the LAME replaygain track gain info has an origin of 'Set automatically'" do
    expect(@lame_info.replay_gain.track_gain.origin).to eq('Set automatically')
  end
  
  it "should verify that the LAME replaygain track gain info has an adjustment of -4.2" do
    expect(@lame_info.replay_gain.track_gain.adjustment).to eq(-4.2)
  end
  
  it "should verify that the LAME replaygain track gain info is formatted similarly to eyeD3's" do
    expect(@lame_info.replay_gain.track_gain.to_s).to eq('Track Replay Gain: -4.2 dB (Set automatically)')
  end
  
  it "should verify that the LAME replaygain tag has album gain info" do
    expect(@lame_info.replay_gain.album_gain).not_to be_nil
  end
  
  it "should verify that the LAME replaygain album gain info is not set" do
    expect(@lame_info.replay_gain.album_gain.set?).to be false
  end
end

describe Mp3Info, "when reading the MP3 info from an encoding of RAC's 'Distance [remake]'" do
  before :all do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/RAC/Double Jointed/02 - RAC - Distance _Remake_.mp3'))
    @mpeg_info = @mp3.mpeg_header
    @xing_info = @mp3.xing_header
    @lame_info = @mp3.lame_header
  end
  
  it "should verify that the MPEG header exists" do
    expect(@mp3.has_mpeg_header?).to be true
  end
  
  it "should find the MPEG header" do
    expect(@mp3.mpeg_header).not_to be_nil
  end
  
  it "should verify that the MPEG is of type 1.0" do
    expect(@mpeg_info.version).to eq(1.0)
  end
  
  it "should verify that the MPEG is layer 3" do
    expect(@mpeg_info.layer).to eq(3)
  end
  
  it "should verify that the MPEG has a sample rate of 44.1kHz" do
    expect(@mpeg_info.sample_rate).to eq(44_100)
  end
  
  it "should verify that the MPEG header claims a bitrate of 128kbps" do
    expect(@mpeg_info.bitrate).to eq(128)
  end
  
  it "should verify that the MPEG is joint stereo" do
    expect(@mpeg_info.mode).to eq('Joint stereo')
  end
  
  it "should verify that the MPEG has a mode extension of M/S stereo" do
    expect(@mpeg_info.mode_extension).to eq(MPEGHeader::MODE_EXTENSION_M_S_STEREO)
  end
  
  it "should verify that the MPEG is not error protected" do
    expect(@mpeg_info.error_protected?).to be false
  end
  
  it "should verify that the MPEG is an original stream" do
    expect(@mpeg_info.original_stream?).to be true
  end
  
  it "should verify that the MPEG is not copyrighted" do
    expect(@mpeg_info.copyrighted_stream?).to be false
  end
  
  it "should verify that the MPEG is not a private stream" do
    expect(@mpeg_info.private_stream?).to be false
  end
  
  it "should verify that the MPEG is not a padded stream" do
    expect(@mpeg_info.padded_stream?).to be false
  end
  
  it "should verify that the MPEG has no emphasis" do
    expect(@mpeg_info.emphasis).to eq(MPEGHeader::EMPHASIS_NONE)
  end
  
  it "should verify that the MPEG has a frame length of 417" do
    expect(@mpeg_info.frame_size).to eq(417)
  end
  
  it "should verify that the Xing header exists" do
    expect(@mp3.has_xing_header?).to be true
  end
  
  it "should verify that there is a Xing header" do
    expect(@mp3.xing_header).not_to be_nil
  end
  
  it "should verify that the Xing header says the stream is VBR" do
    expect(@xing_info.vbr?).to be true
  end
  
  it "should verify that the Xing header says there are 12,900 frames" do
    expect(@xing_info.frames).to eq(12_900)
  end
  
  it "should verify that the Xing header says there are 9,457,829 bytes in the stream" do
    expect(@xing_info.bytes).to eq(9_457_829)
  end
  
  it "should verify that the Xing header contains a table of contents" do
    expect(@xing_info.has_toc?).to be true
  end
  
  it "should verify that the Xing header says the stream has a quality of 78" do
    expect(@xing_info.quality).to eq(78)
  end
  
  it "should verify that the LAME tag exists" do
    expect(@mp3.has_lame_header?).to be true
  end
  
  it "should verify that there is a LAME tag" do
    expect(@mp3.lame_header).not_to be_nil
  end
  
  it "should verify that the LAME tag has a valid header is valid" do
    expect(@lame_info.valid_header?).to be true
  end
  
  it "should verify that the LAME tag has a valid CRC" do
    expect(@lame_info.valid_crc?).to be true
  end
  
  it "should verify that the LAME tag is valid" do
    expect(@lame_info.valid?).to be true
  end
  
  it "should verify that the version of LAME used was 3.90.(3)" do
    expect(@lame_info.encoder_version).to eq("LAME3.90.")
  end
  
  it "should verify that the LAME tag version is 0" do
    expect(@lame_info.tag_version).to eq(0)
  end
  
  it "should verify that the LAME VBR method was old/rh" do
    expect(@lame_info.vbr_method).to eq('Variable Bitrate method1 (old/rh)')
  end
  
  it "should verify that the LAME lowpass frequency was 19kHz" do
    expect(@lame_info.lowpass_filter).to eq(19_000)
  end
  
  it "should verify that the LAME tag has encoder flags" do
    expect(@lame_info.encoder_flags).not_to be_empty
  end
  
  it "should verify that the LAME encoder flags were NSPSYTUNE and NSSAFEJOINT" do
    expect(@lame_info.encoder_flag_string).to eq('--nspsytune --nssafejoint')
  end
  
  it "should verify that the LAME tag has no gapless encoding flags" do
    expect(@lame_info.nogap_flags).to be_empty
  end
  
  it "should verify that the LAME gapless flag string is empty" do
    expect(@lame_info.nogap_flag_string).to eq('')
  end
  
  it "should verify that the LAME tag indicates an ATH type of 4" do
    expect(@lame_info.ath_type).to eq(4)
  end
  
  it "should verify that the LAME tag's CRC is 0x84D9" do
    expect(@lame_info.lame_tag_crc).to eq(0x84D9)
  end
  
  it "should verify that the guaranteed minimum bitrate in the LAME tag is 192" do
    expect(@lame_info.bitrate).to eq(192)
  end
  
  it "should verify that the bitrate type is 'Minimum'" do
    expect(@lame_info.bitrate_type).to eq('Minimum')
  end
  
  it "should verify that the LAME encoding has a delay of 576 samples" do
    expect(@lame_info.encoder_delay).to eq(576)
  end
  
  it "should verify that the LAME padding of 1,464 byte" do
    expect(@lame_info.encoder_padding).to eq(1_464)
  end
  
  it "should verify that the LAME encoding has a noise shaping curve of type 1" do
    expect(@lame_info.noise_shaping_type).to eq(1)
  end
  
  it "should verify that the LAME sample frequency is set to 44.1kHz" do
    expect(@lame_info.sample_frequency).to eq('44.1 kHz')
  end
  
  it "should verify that LAME's settings were not unwise" do
    expect(@lame_info.unwise_settings?).to be false
  end
  
  it "should verify that the LAME stereo mode was 'Joint'" do
    expect(@lame_info.stereo_mode).to eq('Joint')
  end
  
  it "should verify that the LAME tag has an MP3 gain of 0" do
    expect(@lame_info.mp3_gain).to eq(0)
  end
  
  it "should verify that the LAME tag has an MP3 gain of 0dB" do
    expect(@lame_info.mp3_gain_db).to eq(0.0)
  end
  
  it "should verify that the LAME tag has no surround sound info" do
    expect(@lame_info.surround_info).to eq('None')
  end
  
  it "should verify that the LAME preset was unknown (actually alt-preset standard)" do
    expect(@lame_info.preset).to eq('Unknown')
  end
  
  it "should verify that the LAME tag indicates the music length is 9,457,829 bytes" do
    expect(@lame_info.music_length).to eq(9_457_829)
  end
  
  it "should verify that the LAME music CRC is 0xFBD3" do
    expect(@lame_info.music_crc).to eq(0xFBD3)
  end
  
  it "should verify that the LAME tag has replaygain info" do
    expect(@lame_info.replay_gain).not_to be_nil
  end
  
  it "should verify that the LAME tag has no replaygain peak RMS" do
    expect(@lame_info.replay_gain.peak).to be_nil
  end
  
  it "should verify that the LAME tag has no replaygain dB" do
    expect(@lame_info.replay_gain.db).to be_nil
  end
  
  it "should verify that the LAME replaygain tag has track gain info" do
    expect(@lame_info.replay_gain.track_gain).not_to be_nil
  end
  
  it "should verify that the LAME replaygain track gain info is not set" do
    expect(@lame_info.replay_gain.track_gain.set?).to be false
  end
  
  it "should verify that the LAME replaygain tag has no album gain info" do
    expect(@lame_info.replay_gain.album_gain.set?).to be false
  end
end

describe Mp3Info, "when reading the MP3 info from an encoding of Wire's 'I Feel Mysterious Today'" do
  before :all do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Wire/Chairs Missing [Japanese version]/Wire - Chairs Missing [Japanese version] - 12 - I Feel Mysterious Today.mp3'))
    @mpeg_info = @mp3.mpeg_header
    @xing_info = @mp3.xing_header
    @lame_info = @mp3.lame_header
  end
  
  it "should verify that the MPEG header exists" do
    expect(@mp3.has_mpeg_header?).to be true
  end
  
  it "should find the MPEG header" do
    expect(@mp3.mpeg_header).not_to be_nil
  end
  
  it "should verify that the MPEG is of type 1.0" do
    expect(@mpeg_info.version).to eq(1.0)
  end
  
  it "should verify that the MPEG is layer 3" do
    expect(@mpeg_info.layer).to eq(3)
  end
  
  it "should verify that the MPEG has a sample rate of 44.1kHz" do
    expect(@mpeg_info.sample_rate).to eq(44_100)
  end
  
  it "should verify that the MPEG header claims a bitrate of 128kbps" do
    expect(@mpeg_info.bitrate).to eq(128)
  end
  
  it "should verify that the MPEG is joint stereo" do
    expect(@mpeg_info.mode).to eq('Joint stereo')
  end
  
  it "should verify that the MPEG has no mode extension" do
    expect(@mpeg_info.mode_extension).to eq(0) # none
  end
  
  it "should verify that the MPEG is not error protected" do
    expect(@mpeg_info.error_protected?).to be false
  end
  
  it "should verify that the MPEG is an original stream" do
    expect(@mpeg_info.original_stream?).to be true
  end
  
  it "should verify that the MPEG is not copyrighted" do
    expect(@mpeg_info.copyrighted_stream?).to be false
  end
  
  it "should verify that the MPEG is not a private stream" do
    expect(@mpeg_info.private_stream?).to be false
  end
  
  it "should verify that the MPEG is not a padded stream" do
    expect(@mpeg_info.padded_stream?).to be false
  end
  
  it "should verify that the MPEG has no emphasis" do
    expect(@mpeg_info.emphasis).to eq(MPEGHeader::EMPHASIS_NONE)
  end
  
  it "should verify that the MPEG has a frame length of 417" do
    expect(@mpeg_info.frame_size).to eq(417)
  end
  
  it "should verify that the Xing header exists" do
    expect(@mp3.has_xing_header?).to be true
  end
  
  it "should verify that there is a Xing header" do
    expect(@mp3.xing_header).not_to be_nil
  end
  
  it "should verify that the Xing header says the stream is VBR" do
    expect(@xing_info.vbr?).to be true
  end
  
  it "should verify that the Xing header says there are 4,432 frames" do
    expect(@xing_info.frames).to eq(4_432)
  end
  
  it "should verify that the Xing header says there are 2,963,271 bytes in the stream" do
    expect(@xing_info.bytes).to eq(2_963_271)
  end
  
  it "should verify that the Xing header contains a table of contents" do
    expect(@xing_info.has_toc?).to be true
  end
  
  it "should verify that the Xing header says the stream has a quality of 77" do
    expect(@xing_info.quality).to eq(77)
  end
  
  it "should verify that the LAME tag exists" do
    expect(@mp3.has_lame_header?).to be true
  end
  
  it "should verify that there is a LAME tag" do
    expect(@mp3.lame_header).not_to be_nil
  end
  
  it "should verify that the LAME tag has a valid header is valid" do
    expect(@lame_info.valid_header?).to be true
  end
  
  it "should verify that the LAME tag has a valid CRC" do
    expect(@lame_info.valid_crc?).to be true
  end
  
  it "should verify that the LAME tag is valid" do
    expect(@lame_info.valid?).to be true
  end
  
  it "should verify that the version of LAME used was 3.96r" do
    expect(@lame_info.encoder_version).to eq("LAME3.96r")
  end
  
  it "should verify that the LAME tag version is 0" do
    expect(@lame_info.tag_version).to eq(0)
  end
  
  it "should verify that the LAME VBR method was old/rh" do
    expect(@lame_info.vbr_method).to eq('Variable Bitrate method1 (old/rh)')
  end
  
  it "should verify that the LAME lowpass frequency was 19kHz" do
    expect(@lame_info.lowpass_filter).to eq(19_000)
  end
  
  it "should verify that the LAME tag has encoder flags" do
    expect(@lame_info.encoder_flags).not_to be_empty
  end
  
  it "should verify that the LAME encoder flags were NSPSYTUNE and NSSAFEJOINT" do
    expect(@lame_info.encoder_flag_string).to eq('--nspsytune --nssafejoint')
  end
  
  it "should verify that the LAME tag has no gapless encoding flags" do
    expect(@lame_info.nogap_flags).to be_empty
  end
  
  it "should verify that the LAME gapless flag string is empty" do
    expect(@lame_info.nogap_flag_string).to eq('')
  end
  
  it "should verify that the LAME tag indicates an ATH type of 4" do
    expect(@lame_info.ath_type).to eq(4)
  end
  
  it "should verify that the LAME tag's CRC is 0xD487" do
    expect(@lame_info.lame_tag_crc).to eq(0xD487)
  end
  
  it "should verify that bitrate in the LAME tag is set to 128kbps" do
    expect(@lame_info.bitrate).to eq(128)
  end
  
  it "should verify that the bitrate type is 'Minimum'" do
    expect(@lame_info.bitrate_type).to eq('Minimum')
  end
  
  it "should verify that the LAME encoding has a delay of 576 samples" do
    expect(@lame_info.encoder_delay).to eq(576)
  end
  
  it "should verify that the LAME padding of 1,344 bytes" do
    expect(@lame_info.encoder_padding).to eq(1_344)
  end
  
  it "should verify that the LAME encoding has a noise shaping curve of type 1" do
    expect(@lame_info.noise_shaping_type).to eq(1)
  end
  
  it "should verify that the LAME sample frequency is set to 44.1kHz" do
    expect(@lame_info.sample_frequency).to eq('44.1 kHz')
  end
  
  it "should verify that LAME's settings were not unwise" do
    expect(@lame_info.unwise_settings?).to be false
  end
  
  it "should verify that the LAME stereo mode was 'Joint'" do
    expect(@lame_info.stereo_mode).to eq('Joint')
  end
  
  it "should verify that the LAME tag has an MP3 gain of 0" do
    expect(@lame_info.mp3_gain).to eq(0)
  end
  
  it "should verify that the LAME tag has an MP3 gain of 0dB" do
    expect(@lame_info.mp3_gain_db).to eq(0.0)
  end
  
  it "should verify that the LAME tag has no surround sound info" do
    expect(@lame_info.surround_info).to eq('None')
  end
  
  it "should verify that the LAME preset was -V2" do
    expect(@lame_info.preset).to eq('V2')
  end
  
  it "should verify that the LAME tag indicates the music length is 2,963,271 bytes" do
    expect(@lame_info.music_length).to eq(2_963_271)
  end
  
  it "should verify that the LAME music CRC is 0xF82D" do
    expect(@lame_info.music_crc).to eq(0xF82D)
  end
  
  it "should verify that the LAME tag has replaygain info" do
    expect(@lame_info.replay_gain).not_to be_nil
  end
  
  it "should verify that the LAME tag has no replaygain peak RMS" do
    expect(@lame_info.replay_gain.peak).to be_nil
  end
  
  it "should verify that the LAME tag has no replaygain dB" do
    expect(@lame_info.replay_gain.db).to be_nil
  end
  
  it "should verify that the LAME replaygain tag has track gain info" do
    expect(@lame_info.replay_gain.track_gain).not_to be_nil
  end
  
  it "should verify that the LAME replaygain track gain info is set" do
    expect(@lame_info.replay_gain.track_gain.set?).to be true
  end
  
  it "should verify that the LAME replaygain track gain info has a type of 'Track' unlike eyeD3's 'Radio'" do
    expect(@lame_info.replay_gain.track_gain.type).to eq('Track')
  end
  
  it "should verify that the LAME replaygain track gain info has an originator of 'Set automatically'" do
    expect(@lame_info.replay_gain.track_gain.origin).to eq('Set automatically')
  end
  
  it "should verify that the LAME replaygain track gain info has an adjustment of -6.4" do
    expect(@lame_info.replay_gain.track_gain.adjustment).to eq(-6.4)
  end
  
  it "should verify that the LAME replaygain track gain info has a format similar to eyeD3's" do
    expect(@lame_info.replay_gain.track_gain.to_s).to eq('Track Replay Gain: -6.4 dB (Set automatically)')
  end
  
  it "should verify that the LAME replaygain tag has album gain info" do
    expect(@lame_info.replay_gain.album_gain).not_to be_nil
  end
  
  it "should verify that the LAME replaygain album gain info is not set" do
    expect(@lame_info.replay_gain.album_gain.set?).to be false
  end
end

describe Mp3Info, "when reading the MP3 info from an encoding of Jürgen Paape's 'Fruity Loops 1'" do
  before :all do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Jurgen Paape/Speicher 47/01 Fruity Loops 1.mp3'))
    @mpeg_info = @mp3.mpeg_header
  end
  
  it "should verify that the MPEG header exists" do
    expect(@mp3.has_mpeg_header?).to be true
  end
  
  it "should find the MPEG header" do
    expect(@mp3.mpeg_header).not_to be_nil
  end
  
  it "should verify that the MPEG is of type 1.0" do
    expect(@mpeg_info.version).to eq(1.0)
  end
  
  it "should verify that the MPEG is layer 3" do
    expect(@mpeg_info.layer).to eq(3)
  end
  
  it "should verify that the MPEG has a sample rate of 44.1kHz" do
    expect(@mpeg_info.sample_rate).to eq(44_100)
  end
  
  it "should verify that the MPEG header claims a bitrate of 320kbps" do
    expect(@mpeg_info.bitrate).to eq(320)
  end
  
  it "should verify that the MPEG is joint stereo" do
    expect(@mpeg_info.mode).to eq('Joint stereo')
  end
  
  it "should verify that the MPEG has no mode extension" do
    expect(@mpeg_info.mode_extension).to eq(0)
  end
  
  it "should verify that the MPEG is not error protected" do
    expect(@mpeg_info.error_protected?).to be false
  end
  
  it "should verify that the MPEG is an original stream" do
    expect(@mpeg_info.original_stream?).to be true
  end
  
  it "should verify that the MPEG is not copyrighted" do
    expect(@mpeg_info.copyrighted_stream?).to be false
  end
  
  it "should verify that the MPEG is not a private stream" do
    expect(@mpeg_info.private_stream?).to be false
  end
  
  it "should verify that the MPEG is not a padded stream" do
    expect(@mpeg_info.padded_stream?).to be false
  end
  
  it "should verify that the MPEG has no emphasis" do
    expect(@mpeg_info.emphasis).to eq(MPEGHeader::EMPHASIS_NONE)
  end
  
  it "should verify that the MPEG has a frame length of 1,044" do
    expect(@mpeg_info.frame_size).to eq(1_044)
  end
  
  it "should verify that the Xing header doesn't exist" do
    expect(@mp3.has_xing_header?).to be false
  end
  
  it "should verify that there is no Xing header" do
    expect(@mp3.xing_header).to be_nil
  end
  
  it "should verify that the LAME tag doesn't exit" do
    expect(@mp3.has_lame_header?).to be false
  end
  
  it "should verify that there is no LAME tag" do
    expect(@mp3.lame_header).to be_nil
  end
end

describe Mp3Info, "when reading the MP3 info from an encoding of MIA's \"Bamba Banga\" with multiple ID3 tags" do
  before :all do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/MIA/Kala/MIA - Kala - 01 - Bamboo Banga.mp3'))
    @mpeg_info = @mp3.mpeg_header
  end
  
  it "should find an MPEG header" do
    expect(@mp3.has_mpeg_header?).to be true
  end
  
  it "should have a Xing tag" do
    expect(@mp3.has_xing_header?).to be true
  end
  
  it "should have a LAME tag" do
    expect(@mp3.has_lame_header?).to be true
  end
  
  it "should show itself as having been encoded by LAME3.97" do
    expect(@mp3.lame_header.encoder_version).to eq("LAME3.97")
  end
  
  it "should show itself as having been encoded with preset V1" do
    expect(@mp3.lame_header.preset).to eq("V1")
  end
  
  it "should have an ID3v2 tag" do
    expect(@mp3.has_id3v2_tag?).to be true
  end
  
  it "should have 33 ID3V2 frames after merging (although some duplicates should be removed)" do
    expect(@mp3.id3v2_tag.frame_count).to eq(33)
  end
end

describe Mp3Info, "when reading the MP3 info from an encoding a short tone (used for replay testing) with unusual headers" do
  before :all do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Replay Gain RVA2/06-normal-volume.mp3'))
    @mpeg_info = @mp3.mpeg_header
  end
  
  it "should find an MPEG header" do
    expect(@mp3.has_mpeg_header?).to be true
  end
  
  it "should see that the file is an MPEG 1, layer III file" do
    expect(@mpeg_info.version_string).to eq("MPEG1, layer III")
  end
  
  it "should see that the bitrate is 128kbps" do
    expect(@mp3.bitrate).to eq(128)
  end
  
  it "should find an ID3 tag on the file" do
    expect(@mp3.has_id3v1_tag?).to be true
  end
  
  it "should find an ID3v2 tag on the file" do
    expect(@mp3.has_id3v2_tag?).to be true
  end
end
