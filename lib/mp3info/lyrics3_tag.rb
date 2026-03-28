class Lyrics3Tag
  LYRICS_END_V1 = "LYRICSEND".b
  LYRICS_END_V2 = "LYRICS200".b

  attr_reader :version, :size

  def initialize(version, size)
    @version = version
    @size = size
  end

  def self.detect(filename)
    data = File.binread(filename)
    # Lyrics3 tags sit before ID3v1
    search_end = data.size
    search_end -= 128 if data.size >= 128 && data[-128, 3] == "TAG"

    # Check for Lyrics3v2 (more common): ends with "LYRICS200"
    if search_end >= 15 # 6-digit size + "LYRICS200"
      marker_pos = search_end - 9
      if data[marker_pos, 9] == LYRICS_END_V2
        size_str = data[marker_pos - 6, 6]
        tag_size = size_str.to_i
        return new(2, tag_size) if tag_size > 0
      end
    end

    # Check for Lyrics3v1: ends with "LYRICSEND"
    if search_end >= 9
      marker_pos = search_end - 9
      if data[marker_pos, 9] == LYRICS_END_V1
        # v1 doesn't have a size field -- scan backward for "LYRICSBEGIN"
        begin_marker = data.rindex("LYRICSBEGIN".b, marker_pos)
        tag_size = begin_marker ? (marker_pos + 9 - begin_marker) : 0
        return new(1, tag_size)
      end
    end

    nil
  end

  def to_s
    "Lyrics3v#{@version} tag: #{@size} bytes"
  end
end
