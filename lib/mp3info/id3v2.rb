# encoding: utf-8
require_relative 'mpeg_utils'
require_relative 'id3v2_frames'
require_relative 'binary_conversions'
require_relative 'size_units'

using Mp3InfoLib::BinaryConversions
using Mp3InfoLib::SizeUnits

class ID3V2Error < StandardError ; end
class ID3V2ParseError < StandardError ; end
class ID3V2InternalError < StandardError ; end

# This class can be used directly, as it does no I/O of its own.
class ID3V2
  # write_mpeg_file! lives in the module, need it at the class level
  extend MPEGFile
  
  DEFAULT_MAJOR_VERSION = 3
  DEFAULT_MINOR_VERSION = 0

  attr_accessor :write_version
  attr_reader :extended_header
  
  def self.has_id3v2_tag?(filename)
    File.read(filename, 3) == 'ID3'
  end
  
  def self.remove_id3v2_tag!(filename)
    write_mpeg_file!(filename)
  end
  
  def self.from_file(filename)
    File.open(filename, "rb") { |file| from_io(file) }
  end
  
  def to_file(filename)
    File.open(filename, "wb") { |file| file.write(to_bin) }
  end
  
  # assumes file.pos is at the beginning of the ID3v2 tag
  def self.from_io(io)
    # read the tag ID (should always be 'ID3') + the 3-byte ID3v2 header
    raw_tag = io.read(6)
    
    tag_length_string = io.read(4)
    raise(ID3V2Error, "Tag length *must* be stored synchsafe.") unless tag_length_string.synchsafe?
    
    raw_tag << tag_length_string
    
    tag_length = tag_length_string.from_synchsafe_string
    remaining_bytes = io.stat.size - io.pos
    if remaining_bytes >= tag_length
      raw_tag << io.read(tag_length)
      
      $stderr.puts("File has a weird ID3V2 tag length.") if raw_tag.length != tag_length + 10
      id3v2 = ID3V2.new
      id3v2.from_bin(raw_tag)
      $stderr.puts("ID3v2 tag is [#{id3v2.inspect}]") if $DEBUG
    else
      raise(ID3V2Error, "ID3v2 tag found, but not enough bytes in the file to read whole tag (tag length is #{tag_length}, #{remaining_bytes} bytes left in file) [#{raw_tag.inspect}].")
    end
    
    id3v2
  end
  
  def initialize
    @hash = {}

    @write_version = DEFAULT_MAJOR_VERSION
    @extended_header = nil

    # set defaults for everything
    @raw_tag = self.to_bin

    # hash to identify if tag is changed after creation
    @hash_orig = {}
  end
  
  def changed?
    @hash_orig.nil? || @hash_orig != @hash
  end
  
  def valid?
    valid_major_version? && valid_frame_sizes?
  end
  
  def valid_major_version?
    [2, 3, 4].include?(major_version)
  end
  
  def valid_frame_sizes?
    !(major_version == 4 && unsynchronized_tag?(@raw_tag))
  end
  
  # Retrieve a frame by key. Returns the single frame object when there is
  # only one frame for a key, or an array when there are multiple.
  def [](key)
    value = @hash[key]
    return nil if value.nil?
    value.size == 1 ? value.first : value
  end

  # Access the raw array of frames for a key, always as an Array.
  def frames(key)
    @hash[key]
  end

  # Iteration and comparison unwrap single-element arrays for backward compat
  def each
    @hash.each { |k, v| yield k, (v.size == 1 ? v.first : v) }
  end

  def values
    @hash.values.map { |v| v.size == 1 ? v.first : v }
  end

  def ==(other)
    return false unless other.is_a?(Hash) || other.is_a?(ID3V2)
    other_hash = other.is_a?(ID3V2) ? other.to_unwrapped_hash : other
    to_unwrapped_hash == other_hash
  end

  def to_unwrapped_hash
    @hash.transform_values { |v| v.size == 1 ? v.first : v }
  end

  def []=(key, args)
    value = args
    if value.is_a? ID3V24::Frame
      @hash[key] = [value]
    elsif value.is_a? Array
      @hash[key] = value.map { |t| t.is_a?(ID3V24::Frame) ? t : ID3V24::Frame.create_frame(key, t.to_s) }
    else
      @hash[key] = [ID3V24::Frame.create_frame(key, value.to_s)]
    end
  end

  # Override Hash#update to ensure values are always wrapped in arrays
  def update(other_hash)
    other_hash.each { |key, value| self[key] = value }
    self
  end

  def keys
    @hash.keys
  end

  def size
    @hash.size
  end

  def empty?
    @hash.empty?
  end

  def clear
    @hash.clear
  end

  def key?(k)
    @hash.key?(k)
  end
  alias include? key?

  def inspect
    "#<ID3V2(#{to_unwrapped_hash.inspect})>"
  end

  def initialize_copy(source)
    @hash = source.instance_variable_get(:@hash).dup
    @raw_tag = source.instance_variable_get(:@raw_tag).dup
    @hash_orig = source.instance_variable_get(:@hash_orig).dup
    @extended_header = source.instance_variable_get(:@extended_header)&.dup
  end

  def major_version
    @raw_tag[3].ord
  end
  
  def minor_version
    @raw_tag[4].ord
  end
  
  def version
    "2.#{major_version}.#{minor_version}"
  end
  
  def flags
    @raw_tag[5]
  end
  
  def unsynchronized?
    flags.to_binary_array[4] == 1
  end
  
  def extended_header?
    flags.to_binary_array[5] == 1
  end
  
  def experimental?
    flags.to_binary_array[6] == 1
  end
  
  def footer?
    flags.to_binary_array[7] == 1
  end
  
  def frame_count
    @hash.values.sum(&:size)
  end

  def find_frames_by_description(description)
    @hash.values.flat_map do |frames|
      frames.select { |frame| frame.respond_to?(:description) && frame.description == description }
    end
  end
  
  def tag_length
    @raw_tag[6..9].from_synchsafe_string
  end
  
  def description
    <<-DONE
ID3V#{version} tag:

  Tag is #{valid? ? '' : "not "}valid.#{valid_frame_sizes? ? '' : ' (ID3v2.4.0 tag has non-synchsafe frame sizes.)' }

  Major version    : #{major_version}
  Minor version    : #{minor_version}
  Tag size         : #{tag_length.octet_units}

  Tag is #{unsynchronized? ? '' : 'not '}unsynchronized.
  Tag is #{experimental? ? '' : "not "}experimental.
  Tag #{extended_header? ? 'has' : 'does not have'} an extended header.
  Tag #{footer? ? 'has' : 'does not have'} have a footer.

  There are #{frame_count} frames in this tag.

    DONE
  end
  
  def from_bin(string)
    # let's get serious here
    raise(ID3V2ParseError, "Tag started with '#{string[0...3]}' instead of 'ID3'") unless string.index('ID3') == 0
    
    # save the tag to get at the versions and flags after the fact
    @raw_tag = string
    
    raise(ID3V2ParseError, "Major version must be one of 2, 3 or 4 (is #{major_version || 'unknown'})") unless valid_major_version?

    # Preserve the source version for output unless explicitly overridden
    @write_version = major_version

    # Remove unsynchronization if the tag-level flag is set
    tag_data = string
    if unsynchronized?
      # De-unsynchronize: replace \xFF\x00 back to \xFF in the frame data (after 10-byte header)
      header = string[0, 10]
      body = string[10..-1]
      body = body.gsub("\xFF\x00".b, "\xFF".b)
      tag_data = header + body
    end

    $stderr.puts("Parsing ID3v#{version} of length #{"%#010x" % tag_length}...") if $DEBUG
    @hash.update(parse_id3v2_frames(major_version, tag_data))
    @hash_orig = @hash.dup
  end
  
  def to_bin
    #TODO handle TLEN frames
    #TODO add CRC
    if changed?
      tag = ""
      @hash.each_value do |frames|
        next if frames.nil? || frames.empty?
        frames.each { |frame| tag << encode_frame(frame) }
      end
      
      tag_str = "ID3"
      tag_str << [ @write_version, DEFAULT_MINOR_VERSION, "0000" ].pack("CCB4")
      tag_str << tag.bytesize.to_synchsafe_string
      tag_str << tag
      $stderr.puts "ID3V2.to_bin => tag_str=[#{tag_str.inspect}]" if $DEBUG
      tag_str
    else
      raise(ID3V2InternalError,"Can't return an uninitialized tag.") unless defined?(@raw_tag) && !@raw_tag.nil?
      $stderr.puts "ID3V2.to_bin tag unchanged, returning cached raw tag [#{@raw_tag}]." if $DEBUG
      @raw_tag
    end
  end
  
  def merge(other_id3v2)
    # copy frames this tag doesn't know about
    new_frames = other_id3v2.keys - @hash.keys
    new_frames.each { |key| @hash[key] = Array(other_id3v2[key]).dup }

    # merge shared values, deduplicating by ==
    merge_frames = other_id3v2.keys & @hash.keys
    merge_frames.each do |key|
      current_set = @hash[key]
      other_set   = Array(other_id3v2[key])
      merged = current_set + other_set
      out = []
      merged.each { |v| out << v unless out.include?(v) }
      @hash[key] = out
    end
  end
  
  private
  
  def parse_extended_header(version, string, offset)
    ext = {}
    if version == 4
      ext[:size] = string[offset, 4].from_synchsafe_string
      ext[:data_start] = offset + ext[:size]
      flag_count = string[offset + 4].ord
      if flag_count > 0
        ext_flags = string[offset + 5].ord
        ext[:is_update] = (ext_flags & 0x40) != 0
        ext[:has_crc] = (ext_flags & 0x20) != 0
        ext[:has_restrictions] = (ext_flags & 0x10) != 0
        pos = offset + 6
        if ext[:is_update]
          pos += 1  # skip $00 length byte
        end
        if ext[:has_crc]
          pos += 1  # skip $05 length byte
          ext[:crc] = string[pos, 5].from_synchsafe_string
          pos += 5
        end
        if ext[:has_restrictions]
          pos += 1  # skip $01 length byte
          ext[:restrictions] = string[pos].ord
          pos += 1
        end
      end
    else  # v2.3
      ext[:size] = string[offset, 4].to_binary_decimal
      ext[:data_start] = offset + 4 + ext[:size]
      ext_flags = string[offset + 4, 2]
      ext[:has_crc] = (ext_flags[0].ord & 0x80) != 0
      ext[:padding_size] = string[offset + 6, 4].to_binary_decimal
      if ext[:has_crc]
        ext[:crc] = string[offset + 10, 4].to_binary_decimal
      end
    end
    ext
  end

  def encode_frame(frame)
    $stderr.puts("ID3v2.encode_frame(frame=[#{frame.inspect}])") if $DEBUG
    encoded_frame_data = frame.to_s

    header = frame.type[0,4]

    # ID3v2.4 uses synchsafe frame sizes; v2.3 and earlier use plain big-endian
    if @write_version >= 4
      header << encoded_frame_data.bytesize.to_synchsafe_string
    else
      header << [encoded_frame_data.bytesize].pack("N")
    end

    header << "\x00" * 2 # frame flags

    header + encoded_frame_data
  end
  
  def parse_id3v2_frames(version, string)
    $stderr.puts("ID3V2.parse_id3v2_frames(version=#{version},string='#{string[0..255].inspect}...')") if $DEBUG
    frame_hash = {}
    # 3 bytes for 'ID3'
    # 3 bytes for major version, minor version, and header flags
    # 4 bytes for tag size
    cur_pos = 10

    # Parse extended header if present
    @extended_header = nil
    if string[5].ord & 0x40 != 0
      @extended_header = parse_extended_header(version, string, cur_pos)
      cur_pos = @extended_header[:data_start]
    end

    unsynchronized_sizes = true
    if version == 4
      unsynchronized_sizes = unsynchronized_tag?(string)
    end
    
    while cur_pos < string.size do
      name = string.slice(cur_pos, default_width(version))
      cur_pos += default_width(version)
      $stderr.puts("parse_id3v2_frames name is #{name}") if $DEBUG
      
      break if frame_name_invalid?(version, name)

      break if cur_pos + default_width(version) > string.size  # not enough bytes for size

      size = frame_size(string, cur_pos, version, unsynchronized_sizes)
      cur_pos += default_width(version)
      $stderr.puts("parse_id3v2_frames size is #{size}") if $DEBUG
      
      # ID3v2.2 has no frame flags
      frame_flags_raw = nil
      extra_header_bytes = 0
      if version != 2
        break if cur_pos + 2 > string.size
        frame_flags_raw = string.slice(cur_pos, 2)
        cur_pos += 2

        # Parse flag-dependent extra data that precedes the frame body
        if version >= 4
          compressed = (frame_flags_raw[1].ord & 0x08) != 0
          encrypted = (frame_flags_raw[1].ord & 0x04) != 0
          has_group = (frame_flags_raw[1].ord & 0x40) != 0
          frame_unsync = (frame_flags_raw[1].ord & 0x02) != 0
          has_data_length = (frame_flags_raw[1].ord & 0x01) != 0

          extra_header_bytes += 1 if has_group      # group identifier byte
          extra_header_bytes += 1 if encrypted       # encryption method byte
          extra_header_bytes += 4 if has_data_length # synchsafe data length

          if encrypted
            cur_pos += size
            next
          end
        else  # v2.3
          compressed = (frame_flags_raw[1].ord & 0x80) != 0
          encrypted = (frame_flags_raw[1].ord & 0x40) != 0
          has_group = (frame_flags_raw[1].ord & 0x20) != 0
          frame_unsync = false
          has_data_length = false

          extra_header_bytes += 4 if compressed  # decompressed size
          extra_header_bytes += 1 if encrypted   # encryption method
          extra_header_bytes += 1 if has_group   # group identifier

          if encrypted
            cur_pos += size
            next
          end
        end
      else
        compressed = false
        encrypted = false
        frame_unsync = false
      end

      # Extract the frame body, skipping any extra header bytes
      frame_body_start = cur_pos + extra_header_bytes
      frame_body_size = size - extra_header_bytes
      frame_body = string.slice(frame_body_start, frame_body_size)

      # Remove per-frame unsynchronization (v2.4)
      if frame_unsync && frame_body
        frame_body = frame_body.gsub("\xFF\x00".b, "\xFF".b)
      end

      # Decompress zlib-compressed frames
      if compressed && frame_body
        require 'zlib'
        begin
          frame_body = Zlib::Inflate.inflate(frame_body)
        rescue Zlib::DataError => e
          $stderr.puts("Warning: failed to decompress frame '#{name}': #{e.message}") if $DEBUG
          cur_pos += size
          next
        end
      end

      begin
        add_frame(frame_hash, name, frame_body)
      rescue => e
        $stderr.puts("Warning: skipping frame '#{name}' at offset #{cur_pos}: #{e.message}") if $DEBUG
      end
      cur_pos += size
    end
    
    frame_hash
  end
  
  def default_width(version)
    case version
    when 2
      3
    when 3, 4
      4
    end
  end
  
  def frame_name_invalid?(version, name)
    case version
    when 2
      !name.match?(/\A[A-Za-z0-9]{3}\z/)
    when 3, 4
      # bug caused by old tagging application "mp3ext" ( http://www.mutschler.de/mp3ext/ )
      name == "MP3e" or !name.match?(/\A[A-Za-z0-9]{4}\z/)
    end
  end
  
  def frame_size(string, cur_pos, version, unsynchronized = true)
    case version
    when 2
      # 3 bytes for frame size
      string.slice(cur_pos, + 3).to_binary_decimal
    when 3, 4
      if unsynchronized
        # ID3v2.3 does not have synchsafe sizes
        # Also, some badly-written tagging libraries (*cough*) writes ID3v2.4
        # frames with non-synchsafe sizes
        string.slice(cur_pos, + 4).to_binary_decimal
      else
        # ID3v2.4 has synchsafe frame headers
        string.slice(cur_pos, + 4).from_synchsafe_string
      end
    end
  end

  def add_frame(hash, name, string)
    $stderr.puts "ID3V2.add_frame(name='#{name}',string=[#{string[0..255].inspect}...])" if $DEBUG
    frame = ID3V24::Frame.create_frame_from_string(name, string)
    hash[name] ||= []
    hash[name] << frame
  end
  
  # For 2.4.0 tags, try to detect lurking unsynchronized frame size strings
  #
  # I used to handle this by silently fixing up non-synchsafe size strings
  # within mpeg_utils' String.from_synchsafe_string, but this is a per-tag
  # problem, not a per-frame problem, and so all kinds of wacky brokenness
  # was happening at the tag level.
  def unsynchronized_tag?(string)
    # skip all the headers
    cur_pos = 10
    
    while cur_pos < string.size do
      # not verifying names for now
      # name = string.slice(cur_pos, default_width(version))
      cur_pos += 4
      
      size_string = string.slice(cur_pos, 4)
      
      break unless size_string && size_string.size == 4
      
      unless size_string.synchsafe?
        $stderr.puts("ID3V2.unsynchronized_tag? found unsynchronized size %#010x at %#08x" % [size_string.to_binary_decimal, cur_pos]) if $DEBUG
        return true
      end
      
      # increment past the 4-byte size, the 2-byte flags and the tag's content
      cur_pos += 6 + size_string.from_synchsafe_string
    end
    
    false
  end
end
 