require 'mp3info/mpeg_utils'
require 'mp3info/size_utils'

class LAMEReplayGainType
  def initialize(gain_data)
    @raw_frame = gain_data
  end
  
  def set?
    @raw_frame.to_binary_array.slice(3,3).to_binary_decimal != 0
  end
  
  def name
    LAMEReplayGain::NAME[@raw_frame.to_binary_array.slice(0,3).to_binary_decimal] || 'Unknown'
  end
  
  def originator
    LAMEReplayGain::ORIGINATOR[@raw_frame.to_binary_array.slice(3,3).to_binary_decimal] || 'Unknown'
  end
  
  def adjustment
    if sign
      -1 * (@raw_frame.to_binary_array[7..-1].to_binary_decimal / 10.0)
    else
      @raw_frame.to_binary_array[7..-1].to_binary_decimal / 10.0
    end
  end
  
  def to_s
    '%s Replay Gain: %s dB (%s)' % [name, adjustment, originator]
  end
  
  private
  
  def sign
    @raw_frame.to_binary_array.slice(6,1).to_binary_decimal
  end
end

class LAMEReplayGain
  NAME =
    { 0 => 'Not set',
      1 => 'Radio',
      2 => 'Audiophile' }

  ORIGINATOR =
    {  0 => 'Not set',
       1 => 'Set by artist',
       2 => 'Set by user',
       3 => 'Set automatically',
     100 => 'Set by simple RMS average' }

  def initialize(replay_data)
    @raw_frame = replay_data
  end
  
  def peak
    if raw_peak != 0
      raw_peak.to_f / (1 << 28).to_f
    else
      nil
    end
  end
  
  def db
    if raw_peak != 0
      20 * Math::log10(raw_peak)
    else
      nil
    end
  end
  
  def radio
    LAMEReplayGainType.new(@raw_frame.slice(4,2))
  end
  
  def audiophile
    LAMEReplayGainType.new(@raw_frame.slice(6,2))
  end
  
  def to_s
    if radio.set? || audiophile.set?
      (radio.set? ? "\n  #{radio.to_s}" : '') << (audiophile.set? ? "\n  #{audiophile.set}" : '')
    else
      ''
    end
  end
  
  private
  
  def raw_peak
    @raw_frame.slice(0, 4).to_binary_decimal << 5
  end
end

class LAMEHeader
  # 9 bytes that contain the LAME version as a string
  LAME_VERSION_OFFSET          = 0x00
  # 1 byte that contains the VBR mode and the info tag version
  VBR_MODE_TAG_VERSION_OFFSET  = 0x09
  # 1 unsigned byte * 100 = lowpass filter frequency
  LOWPASS_FILTER_OFFSET        = 0x0A
  # 8 bytes of replaygain information
  REPLAYGAIN_OFFSET            = 0x0B
  # 1 byte containing encoder settings flags and the ATH type
  FLAG_NOGAP_ATH_OFFSET        = 0x13
  # 1 byte containing the bitrate (supplemented by presets)
  BITRATE_OFFSET               = 0x14
  # 3 bytes comprising encoder delay and padding in samples
  ENCODER_OFFSET               = 0x15
  # 1 byte of miscellaneous flags, including the cheerful 'unwise settings' flag
  MISC_OFFSET                  = 0x18
  # 1 byte of MP3 gain information
  MP3GAIN_OFFSET               = 0x19
  # 2 bytes containing the surround mode and the encoding preset
  SURROUND_PRESET_OFFSET       = 0x1A
  # 32-bit representation of the length of the music in bytes
  MUSIC_LENGTH_OFFSET          = 0x1C
  # 16-bit CRC for the music
  MUSIC_CRC_OFFSET             = 0x20
  
  # absolute position within the frame of the 16-bit info tag CRC
  LAME_CRC_POSITION            = 0xBE
  
  # from the LAME source:
  # http://lame.cvs.sourceforge.net/*checkout*/lame/lame/libmp3lame/VbrTag.c
  # also borrowed from eyeD3
  CRC16_LOOKUP =
    [ 0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241,
      0xC601, 0x06C0, 0x0780, 0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440,
      0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1, 0xCE81, 0x0E40,
      0x0A00, 0xCAC1, 0xCB81, 0x0B40, 0xC901, 0x09C0, 0x0880, 0xC841,
      0xD801, 0x18C0, 0x1980, 0xD941, 0x1B00, 0xDBC1, 0xDA81, 0x1A40,
      0x1E00, 0xDEC1, 0xDF81, 0x1F40, 0xDD01, 0x1DC0, 0x1C80, 0xDC41,
      0x1400, 0xD4C1, 0xD581, 0x1540, 0xD701, 0x17C0, 0x1680, 0xD641,
      0xD201, 0x12C0, 0x1380, 0xD341, 0x1100, 0xD1C1, 0xD081, 0x1040,
      0xF001, 0x30C0, 0x3180, 0xF141, 0x3300, 0xF3C1, 0xF281, 0x3240,
      0x3600, 0xF6C1, 0xF781, 0x3740, 0xF501, 0x35C0, 0x3480, 0xF441,
      0x3C00, 0xFCC1, 0xFD81, 0x3D40, 0xFF01, 0x3FC0, 0x3E80, 0xFE41,
      0xFA01, 0x3AC0, 0x3B80, 0xFB41, 0x3900, 0xF9C1, 0xF881, 0x3840,
      0x2800, 0xE8C1, 0xE981, 0x2940, 0xEB01, 0x2BC0, 0x2A80, 0xEA41,
      0xEE01, 0x2EC0, 0x2F80, 0xEF41, 0x2D00, 0xEDC1, 0xEC81, 0x2C40,
      0xE401, 0x24C0, 0x2580, 0xE541, 0x2700, 0xE7C1, 0xE681, 0x2640,
      0x2200, 0xE2C1, 0xE381, 0x2340, 0xE101, 0x21C0, 0x2080, 0xE041,
      0xA001, 0x60C0, 0x6180, 0xA141, 0x6300, 0xA3C1, 0xA281, 0x6240,
      0x6600, 0xA6C1, 0xA781, 0x6740, 0xA501, 0x65C0, 0x6480, 0xA441,
      0x6C00, 0xACC1, 0xAD81, 0x6D40, 0xAF01, 0x6FC0, 0x6E80, 0xAE41,
      0xAA01, 0x6AC0, 0x6B80, 0xAB41, 0x6900, 0xA9C1, 0xA881, 0x6840,
      0x7800, 0xB8C1, 0xB981, 0x7940, 0xBB01, 0x7BC0, 0x7A80, 0xBA41,
      0xBE01, 0x7EC0, 0x7F80, 0xBF41, 0x7D00, 0xBDC1, 0xBC81, 0x7C40,
      0xB401, 0x74C0, 0x7580, 0xB541, 0x7700, 0xB7C1, 0xB681, 0x7640,
      0x7200, 0xB2C1, 0xB381, 0x7340, 0xB101, 0x71C0, 0x7080, 0xB041,
      0x5000, 0x90C1, 0x9181, 0x5140, 0x9301, 0x53C0, 0x5280, 0x9241,
      0x9601, 0x56C0, 0x5780, 0x9741, 0x5500, 0x95C1, 0x9481, 0x5440,
      0x9C01, 0x5CC0, 0x5D80, 0x9D41, 0x5F00, 0x9FC1, 0x9E81, 0x5E40,
      0x5A00, 0x9AC1, 0x9B81, 0x5B40, 0x9901, 0x59C0, 0x5880, 0x9841,
      0x8801, 0x48C0, 0x4980, 0x8941, 0x4B00, 0x8BC1, 0x8A81, 0x4A40,
      0x4E00, 0x8EC1, 0x8F81, 0x4F40, 0x8D01, 0x4DC0, 0x4C80, 0x8C41,
      0x4400, 0x84C1, 0x8581, 0x4540, 0x8701, 0x47C0, 0x4680, 0x8641,
      0x8201, 0x42C0, 0x4380, 0x8341, 0x4100, 0x81C1, 0x8081, 0x4040 ]

  ENCODER_FLAGS =
    { 'NSPSYTUNE'   => 0x01,
      'NSSAFEJOINT' => 0x02,
      'NOGAP_NEXT'  => 0x04,
      'NOGAP_PREV'  => 0x08 }

  PRESETS =
    {    0 => 'Unknown',
      # 8 to 320 are reserved for ABR bitrates
       410 => 'V9',
       420 => 'V8',
       430 => 'V7',
       440 => 'V6',
       450 => 'V5',
       460 => 'V4',
       470 => 'V3',
       480 => 'V2',
       490 => 'V1',
       500 => 'V0',
      1000 => 'r3mix',
      1001 => 'standard',
      1002 => 'extreme',
      1003 => 'insane',
      1004 => 'standard/fast',
      1005 => 'extreme/fast',
      1006 => 'medium',
      1007 => 'medium/fast' }

  SAMPLE_FREQUENCIES =
    { 0 => '<= 32 kHz',
      1 => '44.1 kHz',
      2 => '48 kHz',
      3 => '> 48 kHz',}

  STEREO_MODES =
    { 0 => 'Mono',
      1 => 'Stereo',
      2 => 'Dual',
      3 => 'Joint',
      4 => 'Force',
      5 => 'Auto',
      6 => 'Intensity',
      7 => 'Undefined' }

  SURROUND_INFO =
    { 0 => 'None',
      1 => 'DPL encoding',
      2 => 'DPL2 encoding',
      3 => 'Ambisonic encoding',
      8 => 'Reserved' }

  VBR_METHODS =
    { 0 => 'Unknown',
      1 => 'Constant Bitrate',
      2 => 'Average Bitrate',
      3 => 'Variable Bitrate method1 (old/rh)',
      4 => 'Variable Bitrate method2 (mtrh)',
      5 => 'Variable Bitrate method3 (mt)',
      6 => 'Variable Bitrate method4',
      8 => 'Constant Bitrate (2 pass)',
      9 => 'Average Bitrate (2 pass)',
     15 => 'Reserved' }
  
  # requires a valid MPEG frame from the sample file
  def initialize(frame)
    @raw_frame = frame
  end
  
  def encoder_version
    @raw_frame.slice(header_location, 9).strip
  end
  
  def tag_version
    version_and_vbr_byte.slice(0,5).to_binary_decimal
  end
  
  def preset
    case preset_number
    when 8..321
      if nil != vbr_method.index('Average')
        "ABR #{preset_number}"
      else
        "CBR #{preset_number}"
      end
    else
      PRESETS[preset_number] || preset_number
    end
  end
  
  def vbr_method
    VBR_METHODS[version_and_vbr_byte.slice(5,3).to_binary_decimal] || 'Unknown'
  end
  
  def lowpass_filter
    @raw_frame.slice(header_location + LOWPASS_FILTER_OFFSET, 1).to_binary_decimal * 100
  end
  
  def replay_gain
    LAMEReplayGain.new(@raw_frame.slice(header_location + REPLAYGAIN_OFFSET, 8))
  end
  
  def mp3_gain
    if @raw_frame.slice(header_location + MP3GAIN_OFFSET, 1).to_binary_array.first == 1
      -@raw_frame.slice(header_location + MP3GAIN_OFFSET, 1).to_binary_array.slice(1,7).to_binary_decimal
    else
      @raw_frame.slice(header_location + MP3GAIN_OFFSET, 1).to_binary_array.slice(1,7).to_binary_decimal
    end
  end
  
  def mp3_gain_db
    mp3_gain * 1.5
  end
  
  def encoder_flags
    parse_encoder_flags(encoder_nogap_halfbyte)
  end
  
  def encoder_delay
    encoder_sample_statistics.slice(0, 12).to_binary_decimal
  end
  
  def encoder_padding
    encoder_sample_statistics.slice(12, 12).to_binary_decimal
  end
  
  def ath_type
    @raw_frame.slice(header_location + FLAG_NOGAP_ATH_OFFSET, 1).to_binary_array.slice(4,4).to_binary_decimal
  end
  
  def bitrate
    # preset values is more accurate than declared bitrate for ABR / CBR encoding
    if (8..321).include?(preset_number) && bitrate_number >= 255
      preset_number
    else
      bitrate_number
    end
  end
  
  def bitrate_type
    if vbr_method.index('Average') != nil
      'Target'
    elsif vbr_method.index('Variable') != nil
      'Minimum'
    else
      'Constant'
    end
  end
  
  def sample_frequency
    SAMPLE_FREQUENCIES[misc_byte.slice(0, 2).to_binary_decimal] || 'Unknown'
  end
  
  def stereo_mode
    STEREO_MODES[misc_byte.slice(3, 3).to_binary_decimal] || 'Unknown'
  end
  
  def encoder_flag_string
    encoder_flags.join(' ')
  end
  
  def nogap_flags
    parse_nogap_flags(encoder_nogap_halfbyte)
  end
  
  def nogap_flag_string
    nogap_flags.join(' ')
  end
  
  def noise_shaping_type
    misc_byte.slice(6, 2).to_binary_decimal
  end
  
  def surround_info
    SURROUND_INFO[surround_preset_info.slice(2,3).to_binary_decimal] || 'Unknown'
  end
  
  def music_length
    @raw_frame.slice(header_location + MUSIC_LENGTH_OFFSET, 4).to_binary_decimal
  end
  
  def music_crc
    @raw_frame.slice(header_location + MUSIC_CRC_OFFSET, 2).to_binary_decimal
  end
  
  def lame_tag_crc
    @raw_frame.slice(LAME_CRC_POSITION, 2).to_binary_decimal
  end
  
  def unwise_settings?
    misc_byte.slice(2, 1).to_binary_decimal == 1
  end
  
  def valid?
    valid_header? && valid_crc?
  end
  
  def valid_header?
    header_location > 0
  end
  
  def valid_crc?
    check_crc(@raw_frame.slice(0,190)) == lame_tag_crc
  end
  
  def to_s
    "LAME header, #{music_length.octet_units} #{encoder_version} #{sample_frequency} #{preset} stream"
  end
  
  def description
    <<-OUT
LAME tag:

  LAME tag is #{valid? ? '' : 'not '}valid.

  Encoder version  : #{encoder_version}
  Music length     : #{music_length.octet_units}
  Preset           : #{preset}
  VBR method       : #{vbr_method}
  Stereo mode      : #{stereo_mode}
  Sample frequency : #{sample_frequency}
  Lowpass filter   : #{lowpass_filter / 1000} kHz#{replay_gain.to_s}
  LAME tag revision: #{tag_version}
  Encoding flags   : #{encoder_flag_string}#{"\nGapless?            : #{nogap_flag_string}" if nogap_flag_string != ''}
  ATH type         : #{ath_type}
  Bitrate (#{bitrate_type}): #{bitrate} kbps
  MP3 gain         : #{mp3_gain} (#{"% #+4.2g" % mp3_gain_db} dB)
  Encoder delay    : #{encoder_delay} frames
  Encoder padding  : #{encoder_padding} frames
  Noise shaping    : #{noise_shaping_type}
  Unwise settings  : #{unwise_settings?}
  Surround info    : #{surround_info}
  Music CRC-16     : #{"%04X" % music_crc}
  LAME tag CRC-16  : #{"%04X" % lame_tag_crc}

    OUT
  end
  
  private
  
  def encoder_nogap_halfbyte
    @raw_frame.slice(header_location + FLAG_NOGAP_ATH_OFFSET, 1).to_binary_array[0..3].to_binary_decimal
  end
  
  def parse_encoder_flags(byte)
    flags = []
    
    flags << '--nspsytune'   if byte & ENCODER_FLAGS['NSPSYTUNE'] != 0
    flags << '--nssafejoint' if byte & ENCODER_FLAGS['NSSAFEJOINT'] != 0
    flags << '--nogap'       if byte & (ENCODER_FLAGS['NOGAP_NEXT'] | ENCODER_FLAGS['NOGAP_PREV']) != 0
    
    flags
  end
  
  def parse_nogap_flags(byte)
    flags = []
    
    flags << 'before' if byte & ENCODER_FLAGS['NOGAP_PREV'] != 0
    flags << 'after'  if byte & ENCODER_FLAGS['NOGAP_NEXT'] != 0
    
    flags
  end
  
  def encoder_sample_statistics
    @raw_frame.slice(header_location + ENCODER_OFFSET, 3).to_binary_array
  end
  
  def version_and_vbr_byte
    @raw_frame.slice(header_location + VBR_MODE_TAG_VERSION_OFFSET, 1).to_binary_array
  end
  
  def misc_byte
    @raw_frame.slice(header_location + MISC_OFFSET, 1).to_binary_array
  end
  
  def surround_preset_info
    @raw_frame.slice(header_location + SURROUND_PRESET_OFFSET, 2).to_binary_array
  end
  
  def bitrate_number
    @raw_frame.slice(header_location + BITRATE_OFFSET, 1).to_binary_decimal
  end
  
  def preset_number
    surround_preset_info.slice(5,11).to_binary_decimal
  end
  
  def header_location
    @raw_frame.index('LAME') || -1
  end
  
  def check_crc(data)
    crc = 0x0000
    data.each_byte do |c|
      crc = CRC16_LOOKUP[c ^ (crc & 0xff)] ^ (crc >> 8)
    end
    
    crc
  end
end