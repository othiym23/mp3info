# encoding: utf-8
require "delegate"
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
    
    tag_length_synchsafe = io.read(4)
    raw_tag << tag_length_synchsafe
    
    tag_length = tag_length_synchsafe.from_synchsafe_string
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
    valid_major_version?
  end
  
  def valid_major_version?
    [2, 3, 4].include?(major_version)
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
    # ruby 1.9
    if @raw_tag[3].respond_to?(:ord)
      @raw_tag[3].ord
    # ruby < 1.9
    else
      @raw_tag[3]
    end
  end
  
  def minor_version
    # ruby 1.9
    if @raw_tag[4].respond_to?(:ord)
      @raw_tag[4].ord
    # ruby < 1.9
    else
      @raw_tag[4]
    end
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
  
  def tag_length
    @raw_tag[6..9].from_synchsafe_string
  end
  
  def from_bin(string)
    # let's get serious here
    raise(ID3V2ParseError, "Tag started with '#{string[0...3]}' instead of 'ID3'") unless string.index('ID3') == 0
    
    # save the tag to get at the versions and flags after the fact
    @raw_tag = string
    
    raise(ID3V2ParseError, "Can't find version_maj ('#{major_version}')") unless valid_major_version?
    
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
    $stderr.puts("ID3V2.parse_id3v2_frames(version=#{version},string=[#{string.inspect}])") if $DEBUG
    frame_hash = {}
    # 3 bytes for 'ID3'
    # 3 bytes for major version, minor version, and header flags
    # 4 bytes for tag size
    cur_pos = 10
    
    while cur_pos < string.size do
      name = string.slice(cur_pos, default_width(version))
      cur_pos += default_width(version)
      $stderr.puts("parse_id3v2_frames name is #{name}") if $DEBUG
      
      break if frame_name_invalid?(version, name)
      
      size = frame_size(version, cur_pos, string)
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
      0 == (name[0].respond_to?(:ord) ? name[0].ord : name[0])
    when 3, 4
      #bug caused by old tagging application "mp3ext" ( http://www.mutschler.de/mp3ext/ )
      0 == (name[0].respond_to?(:ord) ? name[0].ord : name[0]) or name == "MP3e"
    end
  end
  
  def frame_size(version, cur_pos, string)
    case version
    when 2
      # 3 bytes for frame size
      string[cur_pos..(cur_pos + 2)].to_binary_decimal
    when 3
      # ID3v2.3 does not have synchsafe sizes
      string[cur_pos..(cur_pos + 3)].to_binary_decimal
    when 4
      # ID3v2.4 has synchsafe frame headers
      string[cur_pos..(cur_pos + 3)].from_synchsafe_string
    end
  end

  # Parse a string from a frame
  #
  # An oddity of this class is that it handles multiple frames with the same
  # ID but only returns them as a list if there's more than 1. For consistency's
  # sake this should return a list every time, so consider that a TODO.
  def add_frame(hash, name, string)
    $stderr.puts "ID3V2.add_frame(name='#{name}',string=[#{string.inspect}])" if $DEBUG
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
end
 