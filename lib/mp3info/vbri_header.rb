require_relative "binary_conversions"
require_relative "size_units"

using Mp3InfoLib::BinaryConversions
using Mp3InfoLib::SizeUnits

class VBRIHeader
  VBRI_OFFSET = 36 # Fixed offset from frame start

  def initialize(frame)
    @raw_frame = frame
  end

  def valid?
    @raw_frame.bytesize > VBRI_OFFSET + 26 &&
      @raw_frame[VBRI_OFFSET, 4] == "VBRI"
  end

  def version
    @raw_frame[VBRI_OFFSET + 4, 2].to_binary_decimal
  end

  def delay
    @raw_frame[VBRI_OFFSET + 6, 2].to_binary_decimal
  end

  def quality
    @raw_frame[VBRI_OFFSET + 8, 2].to_binary_decimal
  end

  def bytes
    @raw_frame[VBRI_OFFSET + 10, 4].to_binary_decimal
  end

  def frames
    @raw_frame[VBRI_OFFSET + 14, 4].to_binary_decimal
  end

  def toc_entries
    @raw_frame[VBRI_OFFSET + 18, 2].to_binary_decimal
  end

  def toc_scale
    @raw_frame[VBRI_OFFSET + 20, 2].to_binary_decimal
  end

  def toc_entry_size
    @raw_frame[VBRI_OFFSET + 22, 2].to_binary_decimal
  end

  def toc_frames_per_entry
    @raw_frame[VBRI_OFFSET + 24, 2].to_binary_decimal
  end

  def to_s
    "VBRI header v#{version}, #{frames} frames, #{bytes.octet_units}, quality #{quality}"
  end

  def description
    <<~OUT
      VBRI header:

        VBRI header is #{"not " unless valid?}valid.

        Version          : #{version}
        Quality          : #{quality}
        Stream size      : #{bytes.octet_units}
        Frames           : #{frames}
        TOC entries      : #{toc_entries}

    OUT
  end
end
