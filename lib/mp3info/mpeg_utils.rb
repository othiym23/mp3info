# encoding: binary
require_relative 'binary_conversions'
require_relative 'mpeg_header'
require 'tempfile'

using Mp3InfoLib::BinaryConversions

module MPEGFile
  class MPEGFileError < StandardError ; end
  
  # number of bytes to read in at once in file scanning operations
  CHUNK_SIZE = 2 ** 16
  
  # This method assumes that the file pointer is at the beginning of a frame.
  #
  # It returns either the next frame or the remainder of the stream.
  def read_next_frame(file, frame_size = nil)
    unless frame_size && frame_size > 0
      cur_pos = file.pos
      file.seek(1, IO::SEEK_CUR)
      
      frame_size = 0
      
      begin
        next_pos, data = find_next_frame(file, cur_pos)
        frame_size = next_pos - cur_pos
      rescue MPEGFile::MPEGFileError
        frame_size = file.stat.size - cur_pos
      end
      
      file.seek(cur_pos)
    end
    
    $stderr.puts("Reading %#010x bytes starting at %#010x " % [frame_size, file.pos]) if $DEBUG
    file.read(frame_size)
  end
  
  def write_mpeg_file!(filename)
    raise(MPEGFileError, "File is not writable") unless File.writable?(filename)
    $stderr.puts("MPEGFile::write_mpeg_file! source file length is #{File.size(filename)}") if $DEBUG

    temporary = Tempfile.new('mp3info', File.dirname(filename))
    begin
      tmpfile_path = temporary.path
      File.open(filename, 'rb') do |original|
        # this would be a good place to invoke code to prepend a tag to the file
        yield temporary if block_given?

        # Skip past any existing ID3v2 tag to find where the audio data starts.
        # Read the tag size directly from the header rather than searching for
        # MPEG sync, which can skip valid audio data between the tag and the
        # first frame that passes frame-following validation.
        audio_start = skip_id3v2_tag(original)
        original.seek(audio_start)
        $stderr.puts("MPEGFile::write_mpeg_file! copying audio from %#010x" % audio_start) if $DEBUG

        bufsize = original.stat.blksize || 4096
        while buf = original.read(bufsize)
          temporary.write(buf)
        end
      end
      temporary.close
      File.rename(tmpfile_path, filename)
    rescue
      temporary.close
      temporary.unlink
      raise
    end
  end

  # Skip past an ID3v2 tag at the current file position and return the
  # offset where audio data begins. Returns 0 if there is no ID3v2 tag.
  def skip_id3v2_tag(file)
    file.seek(0)
    header = file.read(3)
    if header == 'ID3'
      file.read(2) # version bytes
      file.read(1) # flags
      size_bytes = file.read(4)
      tag_size = size_bytes.from_synchsafe_string
      10 + tag_size
    else
      0
    end
  end
  
  def find_next_frame(file, start_pos = 0)
    # make sure we've got the sync pattern, let the MPEGHeader validity check do the rest
    first_valid_pos = nil
    first_valid_header = nil

    header_pos, header = find_sync(file, start_pos)
    loop do
      $stderr.puts("MPEGFile::find_next_frame file.pos is %#010x, header_pos is %#010x, header is %#010x" % [file.pos, header_pos, header.to_binary_decimal]) if header && $DEBUG
      break if header.nil?

      if valid_mpeg_header?(header)
        # Remember the first valid candidate as a fallback
        if first_valid_pos.nil?
          first_valid_pos = header_pos
          first_valid_header = header
        end

        # Prefer a frame that is followed by another valid sync
        break if frame_follows?(file, header_pos, header)
      end

      header_pos, header = find_sync(file, header_pos + 1)
    end

    # Use the verified frame, or fall back to the first valid-looking candidate
    if header && valid_mpeg_header?(header)
      return header_pos, header
    elsif first_valid_header
      return first_valid_pos, first_valid_header
    else
      raise(MPEGFileError, "cannot find a valid frame after reading #{"%#010x" % file.pos} bytes from #{file.path} of size #{"%#010x" % file.stat.size}")
    end
  end
  
  def find_sync(file, start_pos = 0)
    $stderr.puts("find_sync seeking to %#010x" % start_pos) if $DEBUG
    file.seek(start_pos)
    file_data = file.read(CHUNK_SIZE)

    while file_data && file_data.size > 0 do
      $stderr.puts("find_sync file data is #{"%#010x" % file_data.size} bytes at %#010x" % start_pos) if $DEBUG

      if sync_pos = file_data.index("\xff")
        header = file_data[sync_pos, 4]
        $stderr.puts("Testing candidate header at #{"%#010x" % (start_pos + sync_pos)}") if $DEBUG
        if header.size == 4
          return start_pos + sync_pos, header
        end
        # sync_pos is within 3 bytes of the end — re-read from that position
        # so the full 4-byte header can be checked in the next iteration
        start_pos += sync_pos
        file.seek(start_pos)
        file_data = file.read(CHUNK_SIZE)
      else
        start_pos += file_data.size
        file_data = file.read(CHUNK_SIZE)
      end
    end

    return nil, nil
  end
  
  def valid_mpeg_header?(header_string)
    MPEGHeader.new(header_string).valid?
  end

  # Verify a candidate frame by checking that the next frame follows at the
  # expected offset. This eliminates false positive sync matches.
  def frame_follows?(file, header_pos, header_string)
    candidate = MPEGHeader.new(header_string)
    return true unless candidate.valid?

    next_pos = header_pos + candidate.frame_size
    return true if next_pos + 4 > file.stat.size  # near EOF, can't check

    saved_pos = file.pos
    file.seek(next_pos)
    next_header = file.read(4)
    file.seek(saved_pos)

    return true unless next_header && next_header.size == 4

    # The next frame should start with a sync pattern (0xFFE0 mask)
    next_header[0].ord == 0xFF && (next_header[1].ord & 0xE0) == 0xE0
  end
end