# encoding: binary

require_relative "binary_conversions"
require_relative "mpeg_header"
require_relative "mpeg_utils"

using Mp3InfoLib::BinaryConversions

# Iterates over MPEG audio frames in an MP3 file, providing access to
# each frame's header, position, and raw data.
class MPEGStream
  include MPEGFile

  # Information about a single MPEG frame
  FrameInfo = Struct.new(
    :position,     # byte offset in the file
    :header,       # MPEGHeader object
    :data,         # raw frame bytes (including header)
    :crc,          # CRC-16 value if error-protected, nil otherwise
    keyword_init: true
  )

  # Information about non-frame data found between frames
  GapInfo = Struct.new(
    :position,     # byte offset where the gap starts
    :size,         # number of bytes
    keyword_init: true
  )

  attr_reader :filename

  def initialize(filename)
    @filename = filename
  end

  # Iterate over every MPEG frame in the file. Yields FrameInfo objects.
  # Optionally yields GapInfo objects for non-frame data if include_gaps is true.
  def each_frame(include_gaps: false)
    return enum_for(:each_frame, include_gaps: include_gaps) unless block_given?

    File.open(@filename, "rb") do |file|
      # Skip past ID3v2 tag at the start
      audio_start = skip_id3v2_tag(file)

      # Determine where audio ends (before ID3v1 tag if present)
      file_size = file.stat.size
      audio_end = file_size
      if file_size >= 128
        file.seek(-128, IO::SEEK_END)
        audio_end = file_size - 128 if file.read(3) == "TAG"
      end

      pos = audio_start
      while pos < audio_end
        file.seek(pos)

        # Try to read a 4-byte header
        header_bytes = file.read(4)
        break unless header_bytes && header_bytes.bytesize == 4

        # Check for sync pattern
        unless header_bytes[0].ord == 0xFF && (header_bytes[1].ord & 0xE0) == 0xE0
          # Not a frame — scan forward for next sync
          sync_start = pos
          pos += 1
          while pos < audio_end
            file.seek(pos)
            byte = file.read(1)
            break unless byte
            if byte.ord == 0xFF
              next_byte = file.read(1)
              break unless next_byte
              if (next_byte.ord & 0xE0) == 0xE0
                # Found potential sync — back up to check
                break
              end
            end
            pos += 1
          end

          if include_gaps && pos > sync_start
            yield GapInfo.new(position: sync_start, size: pos - sync_start)
          end
          next
        end

        # Parse the header
        begin
          header = MPEGHeader.new(header_bytes)
        rescue InvalidMPEGHeader
          pos += 1
          next
        end

        unless header.valid?
          pos += 1
          next
        end

        frame_size = header.frame_size
        if frame_size <= 0 || pos + frame_size > audio_end
          # Truncated or invalid frame
          if pos + frame_size > audio_end && frame_size > 0
            # Truncated final frame — yield what we have
            remaining = audio_end - pos
            file.seek(pos)
            frame_data = file.read(remaining)
            crc = extract_crc(header, frame_data)
            yield FrameInfo.new(
              position: pos,
              header: header,
              data: frame_data,
              crc: crc
            )
          end
          break
        end

        # Read the full frame
        file.seek(pos)
        frame_data = file.read(frame_size)
        break unless frame_data && frame_data.bytesize == frame_size

        crc = extract_crc(header, frame_data)

        yield FrameInfo.new(
          position: pos,
          header: header,
          data: frame_data,
          crc: crc
        )

        pos += frame_size
      end
    end
  end

  # Return all frames as an array (for small files or when you need random access)
  def frames
    each_frame.to_a
  end

  # Quick summary without reading all frame data
  def frame_count
    count = 0
    each_frame { count += 1 }
    count
  end

  private

  def extract_crc(header, frame_data)
    if header.error_protected? && frame_data.bytesize >= 6
      # CRC-16 is 2 bytes immediately after the 4-byte header
      (frame_data[4].ord << 8) | frame_data[5].ord
    end
  end
end
