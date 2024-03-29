require 'mp3info/mpeg_utils'

# lots of stuff can go wrong with an MPEG header
class InvalidMPEGHeader < StandardError ; end

# MPEG headers can be altered with this class, but mostly for testing purposes
class MPEGHeader
  VERSIONS = [2.5, nil, 2.0, 1.0]
  
  EMPHASIS_NONE                 = "none"
  EMPHASIS_5015                 = "50/15 ms"
  EMPHASIS_RESERVED             = "RESERVED"
  EMPHASIS_CCIT                 = "CCIT J.17"
  
  EMPHASISES = [ EMPHASIS_NONE, EMPHASIS_5015, EMPHASIS_RESERVED, EMPHASIS_CCIT ]

  MODE_STEREO                   = 'Stereo'
  MODE_JOINT_STEREO             = 'Joint stereo'
  MODE_DUAL_CHANNEL_STEREO      = 'Dual channel stereo'
  MODE_MONO                     = 'Mono'
  
  MODES = [ MODE_STEREO, MODE_JOINT_STEREO, MODE_DUAL_CHANNEL_STEREO, MODE_MONO ]
  
  # used by Layers 1 & 2
  MODE_EXTENSION_BANDS_4_TO_31  = 0x01
  MODE_EXTENSION_BANDS_8_TO_31  = 0x02
  MODE_EXTENSION_BANDS_12_TO_31 = 0x04
  MODE_EXTENSION_BANDS_16_TO_31 = 0x08
  
  # used by Layer 3
  MODE_EXTENSION_M_S_STEREO     = 0x10
  MODE_EXTENSION_INTENSITY      = 0x20
  
  MODE_EXTENSIONS   = [ MODE_EXTENSION_BANDS_4_TO_31,  MODE_EXTENSION_BANDS_8_TO_31,
                        MODE_EXTENSION_BANDS_12_TO_31, MODE_EXTENSION_BANDS_16_TO_31 ]
  
  #                       MPEG 1    MPEG 2  MPEG 2.5
  SAMPLE_RATES      = [ [ 44_100,   22_050,   11_025 ],
                        [ 48_000,   24_000,   12_000 ],
                        [ 32_000,   16_000,    8_000 ],
                        [    nil,      nil,      nil ] ]
  
  #                           Layer 1  Layer 2  Layer 3
  SAMPLES_PER_FRAME = [ [ nil,    384,    1152,    1152 ],  # MPEG 1
                        [ nil,    384,    1152,     576 ] ] # MPEG 2, 2.5
  
  #                           Layer 1  Layer 2  Layer 3
  COEFFICIENTS      = [ [ nil,     12,     144,     144 ],  # MPEG 1
                        [ nil,     12,     144,      72 ] ] # MPEG 2, 2.5
  
  #                           Layer 1  Layer 2  Layer 3
  SLOT_SIZES        = [ nil,        4,       1,       1 ]
  
  #                           Layer 1  Layer 2  Layer 3
  FRAME_DURATIONS   = [ nil,      384,    1152,    1152 ]
  
  BITRATES = [ [ # MPEG 1
                 [ 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448 ],    # Layer 1
                 [ 0, 32, 48, 56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 384 ],    # Layer2
                 [ 0, 32, 40, 48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320 ] ],  # Layer3
               [ # MPEG 2, 2.5    
                 [ 0, 32, 48, 56,  64,  80,  96, 112, 128, 144, 160, 176, 192, 224, 256 ],    # Layer1
                 [ 0,  8, 16, 24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160 ],    # Layer2
                 [ 0,  8, 16, 24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160 ] ] ] # Layer3
  
  SIDE_INFO_SIZES   = [ [ 32, 17 ],  # MPEG 1
                        [ 17,  9 ] ] # MPEG 2/2.5
  
  LAYER_STRINGS = ['Invalid', 'I', 'II', 'III']
  
  def initialize(header_data)
    @raw_data = header_data.to_binary_decimal
    
    # here's the header layout:
    #
    # sssssssssssvvllp
    # bbbbrrdtmmeecohh
    #
    # see below for how they're used,
    # or refer to http://www.dv.co.yu/mpgscript/mpeghdr.htm
    
    # sssssssssss -- must be all 1s
    @sync = @raw_data >> 16
    
    # vv -- can be one of 1.0, 2.0 or 2.5
    @version = (@raw_data >> 19) & 0x3
    
    # ll -- can't be 0, can be 1, 2, or 3
    @layer = (@raw_data >> 17) & 0x3
    
    # p -- 0 indicates the data following the frame header is a 16-bit CRC
    @error_protection = !(((@raw_data >> 16) & 0x1) == 0x1)
    
    # bbbb -- combined with the version and layer, produces the CBR bitrate for the frame
    # NOTE: ignored in VBR streams, see XingTag for accurate bitrate information
    @bitrate_code = (@raw_data >> 12) & 0xf
    
    # rr -- combined with the version, produces the sample frequency
    @sample_rate_code = (@raw_data >> 10) & 0x3
    
    # d -- 1 indicates the frame is padded with an extra slot,
    # for accurate frame size for given bitrate
    @padded_stream = (@raw_data >> 9) & 0x1
    
    # t -- "private" flag, means something to somebody somewhere
    @private_stream = (@raw_data >> 8) & 0x1
    
    # mm -- used to determine stereo mode
    @mode = (@raw_data >> 6) & 0x3
    
    # ee -- mode extension, used to determine specific attributes of stereo
    # for joint stereo frames
    @mode_extension = (@raw_data >> 4) & 0x3
    
    # c -- 1 indicates stream is copyrighted, most likely never used or respected, ever
    @copyrighted_stream = (@raw_data >> 3) & 0x1
    
    # o -- 1 indicates stream is original encoding of audio stream, likewise probably never used
    @original_stream = (@raw_data >> 2) & 0x1
    
    # hh -- audio emphasis, only used in low-bitrate applications like telephony
    @emphasis = @raw_data & 0x3
  end
  
  def version
    raise InvalidMPEGHeader, "Version code of 1 is reserved by MPEG specification." if 1 == @version
    VERSIONS[@version]
  end
  
  def version_string
    "MPEG#{"%g" % version}, layer #{LAYER_STRINGS[layer]}"
  end
  
  def summary
    "[ #{bitrate}kbps @ #{sample_rate / 1000.0}kHz - #{mode}#{error_protected? ? " +error" : ""} ]"
  end
  
  def layer
    raise InvalidMPEGHeader, "Layer code of 0 is reserved by MPEG specification." if 0 == @layer
    4 - @layer
  end
  
  def padded_stream?
    1 == @padded_stream
  end
  
  def private_stream?
    1 == @private_stream
  end
  
  def copyrighted_stream?
    1 == @copyrighted_stream
  end
  
  def original_stream?
    1 == @original_stream
  end
  
  def error_protected?
    @error_protection
  end
  
  # A bitrate of 0 means 'free', and bitrate for frame should be calculated by decoder.
  # Not used much in practice.
  def bitrate
    raise InvalidMPEGHeader, "Bitrate code of 0x0f is invalid by MPEG specification." if 0x0f == @bitrate_code
    
    BITRATES[lsf][layer - 1][@bitrate_code]
  end
  
  def sample_rate
    case version
    when 2.5
      sample_rate = SAMPLE_RATES[@sample_rate_code][2]
    when 2.0
      sample_rate = SAMPLE_RATES[@sample_rate_code][1]
    when 1.0
      sample_rate = SAMPLE_RATES[@sample_rate_code][0]
    else
      raise InvalidMPEGHeader, "There is no such thing as MPEG #{version}."
    end
    
    raise InvalidMPEGHeader, "Unable to find sample rate for sample rate code #{@sample_rate_code}, MPEG #{version}." unless sample_rate > 0
    
    sample_rate
  end
  
  def samples_per_frame
    SAMPLES_PER_FRAME[lsf][layer]
  end
  
  def mode
    MODES[@mode]
  end
  
  def mode_extension
    case layer
    when 1..2
      extension_flags = MODE_EXTENSIONS[@mode_extension]
    when 3
      extension_flags = (@mode_extension & 0x1) != 0 ? MODE_EXTENSION_INTENSITY : 0
      extension_flags |= MODE_EXTENSION_M_S_STEREO if (@mode_extension & 0x2) != 0
    else
      raise InvalidMPEGHeader, "Layer #{layer} is not supported by the MPEG specification"
    end
    
    extension_flags
  end
  
  def emphasis
    raise InvalidMPEGHeader, "Emphasis code 0x02 is #{EMPHASIS_RESERVED}" if @emphasis == 0x2
    EMPHASISES[@emphasis]
  end
  
  # ISO prescribed method used for computing frame sizes without rounding errors
  def frame_size
    ((COEFFICIENTS[lsf][layer] * bitrate * 1000 / sample_rate) + @padded_stream) * SLOT_SIZES[layer]
  end
  
  def frame_duration
    FRAME_DURATIONS[layer].to_f / sample_rate.to_f
  end
  
  def side_info_size
    SIDE_INFO_SIZES[lsf][mode == MODE_MONO ? 1 : 0]
  end
  
  def valid?
    # see above, but all sync bits must be set to 1
    return false if @sync & 0xffe0 != 0xffe0
    
    # version type of 0x1 is reserved (probably to minimize possibility of confusing sync bitstreams)
    return false if 1 == @version
    
    # layer type of 0x0 is reserved
    return false if 0 == @layer
    
    # bitrate code of 0 indicates a bitrate of 0 (free bitstream), which is supported by almost nothing
    return false if 0x0 == @bitrate_code
    
    # bitrate code of 15 is invalid
    return false if 0xf == @bitrate_code
    
    # 0, 1 and 2 are the only valid sample rate codes
    return false if 0x3 == @sample_rate_code
    
    # there are some oddball restrictions on combining stereo modes and bitrates for layer II
    if 2 == layer
      if [32, 48, 56, 80].include?(bitrate) &&
         MODE_MONO != mode
        return false
      end
      
      if [224, 256, 320, 384].include?(bitrate) &&
         MODE_MONO == mode
        return false
      end
    end
    
    # emphasis type of 0x2 is reserved
    return false if 0x2 == @emphasis
    
    return true
  end
  
  def to_s
    "MPEG header, #{version_string} #{summary}"
  end
  
  def description
    <<-DONE
MPEG header information:

  Frame header is #{valid? ? '' : "not "}valid.

  MPEG version     : #{"%g" % version}
  MPEG layer       : #{LAYER_STRINGS[layer]}
  Bitrate          : #{bitrate} kbps
  Sample frequency : #{sample_rate / 1000.0} kHz
  Channel mode     : #{mode}
  Frame size       : #{frame_size} bytes
  Emphasis         : #{emphasis}
  Mode extension   : #{mode_extension}

  Audio stream is #{error_protected? ? '' : 'not '}error-protected.
  Audio stream is #{private_stream? ? '' : "not "}private.
  Audio stream is #{original_stream? ? '' : "not "}original.
  Audio stream is #{padded_stream? ? '' : "not "}padded.
  Audio stream is #{copyrighted_stream? ? '' : "not "}copyrighted.

    DONE
  end
  
  private
  
  def lsf
    case version
    when 1.0
      0
    else
      1
    end
  end
end
