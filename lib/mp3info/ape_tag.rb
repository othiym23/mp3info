class APETag
  PREAMBLE = "APETAGEX".b
  FOOTER_SIZE = 32

  attr_reader :version, :tag_size, :item_count, :flags

  def initialize(version, tag_size, item_count, flags)
    @version = version
    @tag_size = tag_size
    @item_count = item_count
    @flags = flags
  end

  def self.detect(filename)
    data = File.binread(filename)
    # Try before ID3v1 tag
    search_pos = data.size
    search_pos -= 128 if data.size >= 128 && data[-128, 3] == "TAG"

    return nil if search_pos < FOOTER_SIZE

    footer_start = search_pos - FOOTER_SIZE
    return nil unless data[footer_start, 8] == PREAMBLE

    version = data[footer_start + 8, 4].unpack1("V") # little-endian
    tag_size = data[footer_start + 12, 4].unpack1("V")
    item_count = data[footer_start + 16, 4].unpack1("V")
    flags = data[footer_start + 20, 4].unpack1("V")

    new(version, tag_size, item_count, flags)
  end

  def apev2?
    @version == 2000
  end

  def apev1?
    @version == 1000
  end

  def has_header?
    (@flags & 0x80000000) != 0
  end

  def to_s
    "APEv#{@version / 1000} tag: #{@item_count} items, #{@tag_size} bytes"
  end
end
