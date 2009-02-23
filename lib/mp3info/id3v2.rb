# encoding: utf-8
require 'delegate'
require 'mp3info/compatibility_utils'
require 'mp3info/mpeg_utils'
require "mp3info/id3v2_frames"

# Ruby 1.8<->1.9 compatibility workarounds: should be considered deprecated immediately.
class String
  # There is no String method in both Ruby 1.8 and 1.9 that will return the
  # byte length without resorting to hacks involving regexps. For now,
  # monkeypatching String is my preferred way of hacking around this.
  def safe_length
    if self.respond_to?(:bytesize)
      bytesize
    else
      size
    end
  end
  
  # Ruby 1.9 goes out of its way to make it difficult to quickly
  # smoosh together strings of 'incompatible' encodings. I dislike
  # gratuitous monkeypatching, but this works in both Ruby 1.9 and
  # previous versions.
  def to_s_ignore_encoding
    if self.respond_to?(:force_encoding)
      self.force_encoding("BINARY")
    else
      self
    end
  end
end

class ID3V2Error < StandardError ; end
class ID3V2ParseError < StandardError ; end
class ID3V2InternalError < StandardError ; end

# This class can be used directly, as it does no I/O of its own.
class ID3V2 < DelegateClass(Hash)
  # write_mpeg_file! lives in the module, need it at the class level
  class << self
    include MPEGFile
  end
  
  DEFAULT_MAJOR_VERSION = 4
  DEFAULT_MINOR_VERSION = 0
  
  def ID3V2.has_id3v2_tag?(filename)
    File.read(filename, 3) == 'ID3'
  end
  
  def ID3V2.remove_id3v2_tag!(filename)
    write_mpeg_file!(filename)
  end
  
  def ID3V2.from_file(filename)
    File.open(filename, "rb") { |file| from_io(file) }
  end
  
  def to_file(filename)
    File.open(filename, "w") { |file| file.write(to_bin) }
  end
  
  # assumes file.pos is at the beginning of the ID3v2 tag
  def ID3V2.from_io(io)
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
    # initialize the delegated hash
    @hash = {}
    super(@hash)
    
    # set defaults for everything
    @raw_tag = self.to_bin
    
    # hash to identify if tag is changed after creation
    @hash_orig = {}
  end
  
  def changed?
    !defined?(@hash_orig) || @hash_orig != @hash
  end
  
  def valid?
    valid_major_version? && valid_frame_sizes?
  end
  
  def valid_major_version?
    [2, 3, 4].include?(major_version)
  end
  
  def valid_frame_sizes?
    !(4 == major_version && unsynchronized_tag?(@raw_tag))
  end
  
  def []=(key, args)
    value = args
    if value.is_a? ID3V24::Frame
      @hash[key] = value
    elsif value.is_a? Array
      list = []
      value.each do |thing|
        if thing.is_a? ID3V24::Frame
          list << thing
        else
          list << ID3V24::Frame.create_frame(key, thing.to_s)
        end
      end
      @hash[key] = list
    else
      @hash[key] = ID3V24::Frame.create_frame(key, value.to_s)
    end
  end
  
  def major_version
    @raw_tag[3].to_ordinal
  end
  
  def minor_version
    @raw_tag[4].to_ordinal
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
    count = 0
    values.each do |frames|
      unless frames.is_a?(Array)
        count += 1
      else
        count += frames.size
      end
    end
    
    count
  end
  
  def find_frames_by_description(description)
    found_frames = []
    
    values.each do |frames|
      if frames.is_a?(Array)
        found_frames << frames.select {|frame| frame.respond_to?(:description) && frame.description == description }
      else
        found_frames << frames if frames.respond_to?(:description) && frames.description == description
      end
    end
    
    found_frames.flatten
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
    
    $stderr.puts("Parsing ID3v#{version} of length #{"%#010x" % tag_length}...") if $DEBUG
    @hash.update(parse_id3v2_frames(major_version, string))
    @hash_orig = @hash.dup
  end
  
  def to_bin
    #TODO handle TLEN frames
    #TODO add CRC
    if changed?
      tag = ""
      @hash.each_value do |value|
        next unless value
        next if value.respond_to?("empty?") and value.empty?
        if value.is_a?(Array)
          value.each do |frame|
            tag << encode_frame(frame)
          end
        else
          tag << encode_frame(value)
        end
      end
      
      tag_str = "ID3"
      
      #TODO flags: version_maj, version_min, [unsync, ext_header, experimental, footer]
      tag_str << [ DEFAULT_MAJOR_VERSION, DEFAULT_MINOR_VERSION, "0000" ].pack("CCB4")
      tag_str << tag.safe_length.to_synchsafe_string
      tag_str << tag
      $stderr.puts "ID3V2.to_bin => tag_str=[#{tag_str.inspect}]" if $DEBUG
      tag_str
    else
      raise(ID3V2InternalError,"Can't return an uninitialized tag.") unless defined?(@raw_tag) && nil != @raw_tag
      $stderr.puts "ID3V2.to_bin tag unchanged, returning cached raw tag [#{@raw_tag}]." if $DEBUG
      @raw_tag
    end
  end
  
  def merge(other_id3v2)
    # just copy all the frames this tag doesn't know about
    new_frames   = other_id3v2.keys - @hash.keys
    new_frames.each { |key| @hash[key] = other_id3v2[key].dup }
    
    # merge the shared values
    merge_frames = other_id3v2.keys & @hash.keys
    merge_frames.each do |key|
      current_set = self[key].is_a?(Array) ? self[key] : [self[key]]
      other_set   = other_id3v2[key].is_a?(Array) ? other_id3v2[key] : [other_id3v2[key]]
      merged_set  = current_set + other_set
      out = []
      merged_set.each { |value| out << value if !out.include?(value) }
      @hash[key] = out.size == 1 ? out.first : out
    end
  end
  
  private
  
  def encode_frame(frame)
    $stderr.puts("ID3v2.encode_frame(frame=[#{frame.inspect}])") if $DEBUG
    encoded_frame_data = frame.to_s
    
    # 4 characters max for a tag's key
    header = frame.type[0,4] 
    
    # ID3v2.4 has synch safe frame headers
    if major_version == 4
      header << encoded_frame_data.safe_length.to_synchsafe_string
    else
      header << encoded_frame_data.safe_length.to_binary_string
    end
    
    header << "\x00" * 2 # TODO: frame flags
    
    header + encoded_frame_data
  end
  
  def parse_id3v2_frames(version, string)
    $stderr.puts("ID3V2.parse_id3v2_frames(version=#{version},string='#{string[0..255].inspect}...')") if $DEBUG
    frame_hash = {}
    # 3 bytes for 'ID3'
    # 3 bytes for major version, minor version, and header flags
    # 4 bytes for tag size
    cur_pos = 10
    
    unsynchronized_sizes = true
    if 4 == version
      unsynchronized_sizes = unsynchronized_tag?(string)
    end
    
    while cur_pos < string.size do
      name = string.slice(cur_pos, default_width(version))
      cur_pos += default_width(version)
      $stderr.puts("parse_id3v2_frames name is #{name}") if $DEBUG
      
      break if frame_name_invalid?(version, name)
      
      size = frame_size(string, cur_pos, version, unsynchronized_sizes)
      cur_pos += default_width(version)
      $stderr.puts("parse_id3v2_frames size is #{size}") if $DEBUG
      
      # ID3v2.2 lacks the awesomely useful frame flags of later versions
      # TODO do something useful with the frame flags
      if 2 != version
        frame_flags = string.slice(cur_pos, 2)
        cur_pos += 2
        $stderr.puts("parse_id3v2_frames flags are #{frame_flags.inspect}") if $DEBUG
      end
      
      add_frame(frame_hash, name, string.slice(cur_pos, size))
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
      name.match(/[A-Za-z0-9]{3}/) == nil
    when 3, 4
      # bug caused by old tagging application "mp3ext" ( http://www.mutschler.de/mp3ext/ )
      name == "MP3e" or name.match(/[A-Za-z0-9]{4}/) == nil
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

  # Parse a string from a frame
  #
  # An oddity of this class is that it handles multiple frames with the same
  # ID but only returns them as a list if there's more than 1. For consistency's
  # sake this should return a list every time, so consider that a TODO.
  def add_frame(hash, name, string)
    $stderr.puts "ID3V2.add_frame(name='#{name}',string=[#{string[0..255].inspect}...])" if $DEBUG
    frame = ID3V24::Frame.create_frame_from_string(name, string)
    if hash.keys.include?(name)
      unless hash[name].is_a?(Array)
        hash[name] = [hash[name]]
      end
      hash[name] << frame
    else
      hash[name] = frame
    end
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
 