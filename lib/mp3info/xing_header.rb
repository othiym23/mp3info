require 'mp3info/mpeg_utils'
require 'mp3info/mpeg_header'
require 'mp3info/size_utils'

class XingHeaderError < StandardError ; end

class XingHeader
  FRAMES_FLAG    = 0x0001
  BYTES_FLAG     = 0x0002
  TOC_FLAG       = 0x0004
  VBR_SCALE_FLAG = 0x0008
  
  def initialize(frame)
    @raw_frame = frame
    @mpeg_header = MPEGHeader.new(frame.slice(0,4))
  end

  def valid?
    ['Xing', 'Info'].include?(@raw_frame.slice(XingHeader.header_to_offset(@mpeg_header), 4))
  end

  def vbr?
    @raw_frame.slice(XingHeader.header_to_offset(@mpeg_header), 4) == 'Xing'
  end
  
  def has_framecount?
    header_flags & FRAMES_FLAG != 0
  end
  
  def has_bytecount?
    header_flags & BYTES_FLAG != 0
  end
  
  def has_toc?
    header_flags & TOC_FLAG != 0
  end
  
  def has_quality_scale?
    header_flags & VBR_SCALE_FLAG != 0
  end
  
  def frames
    if has_framecount?
      @raw_frame.slice(framecount_offset, 4).to_binary_decimal
    else
      0
    end
  end
  
  def bytes
    if has_bytecount?
      @raw_frame.slice(bytecount_offset, 4).to_binary_decimal
    else
      0
    end
  end
  
  def table_of_contents
    if has_toc?
      @raw_frame.slice(toc_offset, 100)
    else
      ""
    end
  end
  
  def quality
    if has_quality_scale?
      @raw_frame.slice(quality_scale_offset, 4).to_binary_decimal
    else
      0
    end
  end
  
  def self.header_to_offset(header)
    if 1 == header.version
      if header.mode_extension == (MPEGHeader::MODE_EXTENSION_BANDS_4_TO_31 | MPEGHeader::MODE_EXTENSION_BANDS_8_TO_31)
        17 + 4
      else
        32 + 4
      end
    else
      if header.mode_extension == (MPEGHeader::MODE_EXTENSION_BANDS_4_TO_31 | MPEGHeader::MODE_EXTENSION_BANDS_8_TO_31)
        9 + 4
      else
        17 + 4
      end
    end
  end
  
  def to_s
    "Xing header, #{vbr? ? 'VBR' : 'CBR'} encoded with #{frames} frames and a stream size of #{bytes.octet_units}."
  end
  
  private
  
  def header_flags_offset
    XingHeader.header_to_offset(@mpeg_header) + 4 # 4 bytes for header -- Xing or LAME
  end
  
  def framecount_offset
    header_flags_offset + 4 # 4 bytes for flags
  end
  
  def bytecount_offset
    framecount_offset + (has_framecount? ? 4 : 0)
  end
  
  def toc_offset
    bytecount_offset + (has_bytecount? ? 4 : 0)
  end
  
  def quality_scale_offset
    toc_offset + (has_toc? ? 100 : 0)
  end
  
  def header_flags
    @raw_frame.slice(header_flags_offset, 4).to_binary_decimal
  end
end