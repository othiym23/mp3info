# mutually dependent files do not make me happy.
require 'mp3info/mpeg_header'
require 'tempfile'

#
# Initially ported from eyeD3 by Ryan Finne & Travis Shirk.
#
class String
  # convert a string representing an array of big-endian bytes into an array of bits
  def to_binary_array(size = 8)
    if (size < 1 or size > 8)
      raise ArgumentError, size.to_s + ' is not a valid word size.'
    end
    
    binary_array = [];

    self.each_byte do |byte|
      bits = [];
      size.downto(1) { |bit| bits << byte[bit - 1] }
      
      binary_array += bits
    end
    
    binary_array
  end
  
  # convert a string representing an array of big-endian bytes into its arbitrarily wide Fixnum value
  def to_binary_decimal
    to_binary_array.to_binary_decimal
  end
  
  def from_synchsafe_string
    # At first, second and third glance this is an incredible hack,
    # but mixing and matching ID3v2.4 and non-syncsafe lengths is very common,
    # including previous builds of this library. Easier to patch it here
    # than have to special-case it everywhere else.
    unless (to_binary_decimal & 0x80808080) > 1
      to_binary_array(7).to_binary_decimal
    else
      to_binary_decimal
    end
  end
end

class Array
  # encode a binary array of big-endian bytes back into a string
  def to_binary_string
    binary_string = ''

    binary_list = self.reverse

    chunks = binary_list.size / 8
    chunks += 1 if (binary_list.size % 8 > 0)

    chunks.times do |cur_slice|
      byte = 0

      binary_list[8 * cur_slice, 8].each_with_index do |bit,index|
        raise ArgumentError, "Array must contain only '1' or '0', not '#{bit}'" unless bit == 0 || bit == 1
        byte |= bit << index
      end

      binary_string += byte.chr
    end

    binary_string.reverse
  end
  
  # encode a binary array of big-endian bytes into a decimal value
  def to_binary_decimal
    decimal = 0

    binary_list = self.reverse

    binary_list.each_with_index do |bit,index|
      raise ArgumentError, "Array must contain only '1' or '0', not '#{bit}'" unless bit == 0 || bit == 1
      decimal += bit << index
    end

    decimal
  end
end

class Fixnum
  # encode a decimal into a binary array
  def to_binary_array(padding = 0)
    raise ArgumentError, "Only positive numbers can be translated" if self < 0
    raise ArgumentError, "Padding value must be positive" if padding < 0
    
    binary_array = []
    
    raw_value = self
    while raw_value > 0 do
      binary_array << (raw_value & 1)
      raw_value >>= 1
    end

    ([ 0 ] * ((padding - binary_array.size) > 0 ? padding - binary_array.size : 0)) + binary_array.reverse
  end
  
  # encode a decimal back into a string
  def to_binary_string(padding = 0)
    to_binary_array(padding).to_binary_string
  end
  
  def to_synchsafe_string
    raise ArgumentError, "Only positive numbers can be translated" if self < 0
    raise ArgumentError, "Synchsafe value must be less than 2^28 - 1" if self > 268435455
    
    binary_string = ''
    
    binary_string += ((self >> 21) & 0x7f).chr
    binary_string += ((self >> 14) & 0x7f).chr
    binary_string += ((self >>  7) & 0x7f).chr
    binary_string += ((self >>  0) & 0x7f).chr
    
    binary_string
  end
end

class Bignum
  # encode a decimal into a binary array
  def to_binary_array(padding = 0)
    raise ArgumentError, "Only positive numbers can be translated" if self < 0
    raise ArgumentError, "Padding value must be positive" if padding < 0
    
    binary_array = []
    
    raw_value = self
    while raw_value > 0 do
      binary_array << (raw_value & 1)
      raw_value >>= 1
    end

    ([ 0 ] * ((padding - binary_array.size) > 0 ? padding - binary_array.size : 0)) + binary_array.reverse
  end
  
  # encode a decimal back into a string
  def to_binary_string(padding = 0)
    to_binary_array(padding).to_binary_string
  end
end

module MPEGFile
  class MPEGFileError < StandardError ; end
  
  # number of bytes to read in at once in file scanning operations
  CHUNK_SIZE = 2 ** 16
  
  # This method assumes that the file pointer is at the beginning of a frame.
  #
  # It returns either the next frame or the remainder of the stream.
  def read_next_frame(file)
    cur_pos = file.pos
    file.seek(1, IO::SEEK_CUR)
    
    frame_size = 0
    
    begin
      # find_next_frame is defined in MPEGFile
      next_pos, data = find_next_frame(file)
      frame_size = next_pos - cur_pos
    rescue MPEGFile::MPEGFileError
      frame_size = file.stat.size - cur_pos
    end
    
    file.seek(cur_pos)
    file.read(frame_size)
  end
  
  def write_mpeg_file!(filename)
    raise(MPEGFileError, "File is not writable") unless File.writable?(filename)
    $stderr.puts("MPEGFile::write_mpeg_file! source file length is #{File.size(filename)}") if $DEBUG
    
    tmpfile_path = nil
    File.open(filename, 'rb') do |original|
      Tempfile.open('mp3info', File.dirname(filename)) do |temporary|
        tmpfile_path = temporary.path
        
        # this would be a good place to invoke code to prepend a tag to the file
        yield temporary if block_given?
        
        $stderr.puts("MPEGFile::write_mpeg_file! about to call find_next_frame, file.pos=#{original.pos}") if $DEBUG
        header_pos, header = find_next_frame(original)
        original.seek(header_pos)
        $stderr.puts("MPEGFile::write_mpeg_file! original file is at location #{original.pos}") if $DEBUG
        bufsize = original.stat.blksize || 4096
        while buf = original.read(bufsize)
          temporary.write(buf)
          $stderr.puts("MPEGFile::write_mpeg_file! wrote #{bufsize} bytes of the original file to #{tmpfile_path}") if $DEBUG
        end
      end
    end
    File.rename(tmpfile_path, filename)
  end
  
  def find_next_frame(file)
    header_pos = 0
    header = nil
    
    # make sure we've got the sync pattern, let the MPEGHeader validity check do the rest
    cur_pos = file.pos
    loop do
      header_pos, header = find_sync(file, cur_pos)
      $stderr.puts("MPEGFile::find_next_frame file.pos is %u, header_pos is %u, header is %#x" % [file.pos, header_pos, header.to_binary_decimal]) if header && $DEBUG
      break if nil == header || valid_mpeg_header?(header)
      cur_pos = header_pos + 1
    end
    
    if header
      return header_pos, header
    else
      raise(MPEGFileError, "cannot find a valid frame after reading #{file.pos} bytes from #{file.path} of size #{file.stat.size}")
    end
  end
  
  def find_sync(file, start_pos=0)
    file.seek(start_pos)
    file_data = file.read(CHUNK_SIZE)
    
    while file_data do
      sync_pos = file_data.index(0xff)
      if sync_pos
        header = file_data.slice(sync_pos, 4)
        if 4 == header.size
          return start_pos + sync_pos, header
        end
      end
      
      file_data = file.read(CHUNK_SIZE)
    end
    
    return nil, nil
  end
  
  def valid_mpeg_header?(header_string)
    MPEGHeader.new(header_string).valid?
  end
end