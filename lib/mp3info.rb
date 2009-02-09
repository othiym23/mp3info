# $Id: mp3info.rb,v 730e44b0259d 2009/02/09 08:18:39 ogd $
# License:: Ruby
# Author:: Forrest L Norvell (mailto:ogd_AT_aoaioxxysz_DOT_net)
# Author:: Guillaume Pierronnet (mailto:moumar_AT__rubyforge_DOT_org)
# Website:: http://ruby-mp3info.rubyforge.org/
script_path = __FILE__
script_path = File.readlink(script_path) if File.symlink?(script_path)

$: << File.join(File.dirname(script_path), '../lib')

require 'delegate'
require 'fileutils'
require 'tempfile'
require 'mp3info/mpeg_header'
require 'mp3info/xing_header'
require 'mp3info/id3'
require 'mp3info/id3v2'

# ruby -d to display debugging info

# Raised on any kind of error related to ruby-mp3info
class Mp3InfoError < StandardError ; end

class Mp3Info
  VERSION = "0.6"
  
  V1_V2_TAG_MAPPING = { 
    "title"    => "TIT2",
    "artist"   => "TPE1", 
    "album"    => "TALB",
    "year"     => "TYER",
    "tracknum" => "TRCK",
    "comments" => "COMM",
    "genre_s"  => "TCON"
  }

  # number of bytes to read in at once in file scanning operations
  CHUNK_SIZE = 2 ** 16
  
  # MPEG header
  attr_reader :mpeg_header
  
  # Xing header
  attr_reader :xing_header
  
  # mpeg version = 1 or 2
  def mpeg_version
    @mpeg_header.version
  end

  # layer = 1, 2, or 3
  def layer
    @mpeg_header.layer
  end

  # bitrate in kbps
  def bitrate
    if has_xing_header?
      (((@xing_header.bytes / @xing_header.frames) * samplerate) / 144) >> 10
    elsif has_mpeg_header?
      @mpeg_header.bitrate
    else
      0
    end
  end

  # samplerate in Hz
  def samplerate
    @mpeg_header.sample_rate
  end

  # channel mode => "Stereo", "JStereo", "Dual Channel" or "Single Channel"
  def channel_mode
    @mpeg_header.mode
  end

  # variable bitrate => true or false
  attr_reader :vbr

  # length in seconds as a Float
  attr_reader :length

  # error protection => true or false
  def error_protection
    @mpeg_header.error_protection
  end

  #a sort of "universal" tag, regardless of the tag version, 1 or 2, with the same keys as @tag1
  #this tag has priority over @tag1 and @tag2 when writing the tag with #close
  attr_reader :tag

  # The ID3v2 tag is a class that acts as a hash. You can update it and it will
  # be written out when the file is closed.
  attr_reader :tag1
  
  def tag1=(new_hash)
    @tag1 = ID3.new unless hastag1?
    @tag1.update(new_hash)
  end
  
  # id3v2 tag attribute as an ID3V2 object. You can modify it, it will be written when calling
  # "close" method.
  attr_accessor :tag2

  # the original filename
  attr_reader :filename

  # Moved hastag1? and hastag2? to be booleans
  attr_reader :hastag1, :hastag2

  # expose the raw size of the tag for quality-checking purposes
  attr_reader :tag_size
  
  def self.hastag1?(filename)
    File.open(filename) { |f|
      f.seek(-ID3::TAGSIZE, File::SEEK_END)
      f.read(3) == "TAG"
    }
  end

  def self.hastag2?(filename)
    File.open(filename) { |f|
      f.read(3) == "ID3"
    }
  end

  def self.removetag1(filename)
    if self.hastag1?(filename)
      newsize = File.size(filename) - ID3::TAGSIZE
      File.open(filename, "rb+") { |f| f.truncate(newsize) }
    end
  end
  
  def self.removetag2(filename)
    self.open(filename) do |mp3|
      mp3.tag2 = nil
    end
  end
  
  def hastag?
    defined?(@tag)
  end

  def hastag1?
    defined?(@tag1) && nil != @tag1 && @tag1.valid?
  end

  def hastag2?
    defined?(@tag2) && nil != @tag2 && @tag2.valid?
  end
  
  def has_xing_header?
    defined?(@xing_header) && nil != @xing_header
  end
  
  def has_mpeg_header?
    defined?(@mpeg_header) && nil != @mpeg_header
  end
  
  def removetag1
    if Mp3Info.hastag1?(@filename)
      newsize = File.size(@filename) - ID3::TAGSIZE
      $stderr.puts("Mp3Info.removetag1 has ID3v1 tag, file will have new size #{newsize}.") if $DEBUG
      File.truncate(@filename, newsize)
    end
    
    if hastag1?
      @tag1 = nil
    end
  end
  
  def removetag2
    @tag2.clear
  end

  # Instantiate a new Mp3Info object with name +filename+
  def initialize(filename)
    # read in ID3v2 tag, MPEG info, and ID3 tag (if present) in a single pass
    @filename = filename
    file = File.new(@filename, "rb")
    
    total_bytes = file.stat.size
    
    #
    # read tags at beginning of file
    #
    case file.read(3)
    when 'TAG' # ID3 tag at the beginning of the file (unusual)
      $stderr.puts("Mp3Info.initialize TAG found at beginning of file") if $DEBUG
      file.seek(-3, IO::SEEK_CUR)
      @tag1 = load_id3_1_tag(file)
      $stderr.puts("Mp3Info.initialize ID3 tag is #{@tag1.inspect}") if $DEBUG
    when 'ID3' # ID3v2 tag
      $stderr.puts("Mp3Info.initialize ID3 found at beginning of file") if $DEBUG
      file.seek(-3, IO::SEEK_CUR)
      @tag2 = load_id3_2_tag(file)
    else
      $stderr.puts("Mp3Info.initialize no tag found at beginning of file") if $DEBUG
      file.seek(0)
    end
    
    #
    # if anything is left after reading tags, read MPEG data
    #
    cur_pos = file.pos
    begin
      $stderr.puts("Mp3Info.initialize about to call find_next_frame, file.pos=#{file.pos}") if $DEBUG
      header_pos, header_data = find_next_frame(file)
      mpeg_candidate = MPEGHeader.new(header_data)
      @mpeg_header = mpeg_candidate if mpeg_candidate.valid?
      $stderr.puts("MPEG header found, is [#{@mpeg_header.inspect}]") if $DEBUG && @mpeg_header
      
      file.seek(header_pos)
      cur_frame = read_next_frame(file)
      xing_candidate = XingHeader.new(cur_frame)
      @xing_header = xing_candidate if xing_candidate.valid?
      $stderr.puts("Xing header found, is [#{@xing_header.to_s}]") if $DEBUG && @xing_header
    rescue Mp3InfoError
      $stderr.puts("Mp3Info.initialize guesses there's no MPEG frames in this file.") if $DEBUG
      file.seek(cur_pos)
    end
    
    #
    # calculate the CBR bitrate, streamsize, length
    #
    if has_mpeg_header? && !has_xing_header?
      # for cbr, calculate duration with the given bitrate
      @streamsize = file.stat.size - (hastag1? ? ID3::TAGSIZE : 0) - ((hastag2? ? (@tag2.tag_length + 10) : 0))
      @length = ((@streamsize << 3) / 1000.0) / bitrate
      if hastag2? && @tag2['TLEN']
        # but if another duration is given and it isn't close (within 5%)
        #  assume the mp3 is vbr and go with the given duration
        tlen = (@tag2['TLEN'].is_a?(Array) ? @tag2['TLEN'].last : @tag2['TLEN']).value.to_i / 1000
        percent_diff = ((@length.to_i - tlen) / tlen.to_f)
        if percent_diff.abs > 0.05
          # without the Xing header, this is the best guess without reading
          #  every single frame
          @vbr = true
          @length = tlen
          @bitrate = (@streamsize / bitrate) >> 10
        end
      end
    end
    
    #
    # check for an ID3 tag at the end
    #
    if (total_bytes >= ID3::TAGSIZE)
      file.seek(-ID3::TAGSIZE, IO::SEEK_END)
      if file.read(3) == 'TAG'
        file.seek(-3, IO::SEEK_CUR)
        if hastag1?
          @tag1.update(load_id3_1_tag(file))
        else
          @tag1 = load_id3_1_tag(file)
        end
      end
    end
    
    file.close
    
    load_universal_tag!
    
    if !(hastag1? || hastag2? || has_mpeg_header? || has_xing_header?)
      raise(Mp3InfoError, "There was no useful metadata in #{@filename}, are you sure it's an MP3?")
    end
  end
  
  # Flush pending modifications to tags and close the file
  def close
    $stderr.puts("Mp3Info.close") if $DEBUG
    
    prepare_universal_tag!
    save_id3v1_changes!
    update_file_with_changed_id3v2!
  end

  # "block version" of Mp3Info::new()
  def self.open(filename)
    m = self.new(filename)
    ret = nil
    if block_given?
      begin
        ret = yield(m)
      ensure
        m.close
      end
    else
      ret = m
    end
    ret
  end
  
  def load_id3_1_tag(io)
    if io.stat.size >= ID3::TAGSIZE
      raw_tag = io.read(ID3::TAGSIZE)
      
      id3 = ID3.new
      id3.from_bin(raw_tag)
    else
      $stderr.puts("file looks like it has an ID3 tag at the start, but isn't big enough to contain one.")
      io.seek(0)
    end
    
    id3
  end
  
  def load_id3_2_tag(io)
    # read the tag ID (should always be 'ID3')
    raw_tag = io.read(3)
    # read the ID3 header
    raw_tag << io.read(3)
    
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
      raise(Mp3InfoError, "ID3v2 tag found, but not enough bytes in the file to read whole tag (tag length is #{tag_length}, #{remaining_bytes} bytes left in file) [#{raw_tag.inspect}].")
    end
    
    id3v2
  end
  
  # write to another filename at close()
  def rename(new_filename)
    @filename = new_filename
  end

  # inspect inside Mp3Info
  def to_s
    time = "Time: #{time_string}"
    type = "MPEG#{mpeg_version} Layer #{layer}"
    properties = "[ #{@vbr ? "~" : ""}#{bitrate}kbps @ #{samplerate / 1000.0}kHz - #{channel_mode} ]#{error_protection ? " +error" : ""}"
    
    # try to always keep the string representation at 80 characters
    "#{time}#{" " * (18 - time.size)}#{type}#{" " * (62 - (type.size + properties.size))}#{properties}"
  end

  private

  def load_universal_tag!
    @tag = {}
    
    if hastag1?
      @tag = @tag1.dup
    end
    
    if hastag2?
      @tag = {}
      V1_V2_TAG_MAPPING.each do |key1, key2| 
        t2 = @tag2[key2]
        next unless t2
        @tag[key1] = t2.is_a?(Array) ? t2.first.value : t2.value

        if key1 == "tracknum"
          val = @tag2[key2].is_a?(Array) ? @tag2[key2].first.value : @tag2[key2].value
          @tag[key1] = val.to_i
        end
      end
    end
    
    @tag_orig = @tag.dup
  end
  
  def prepare_universal_tag!
    if hastag? && @tag != @tag_orig
      $stderr.puts("Mp3Info.prepare_universal_tag! universal tag has changed") if $DEBUG
      if !(hastag1? || hastag2?)
        @tag2 = ID3V2.new
      end
      
      if hastag1?
        @tag.each do |k, v|
          @tag1[k] = v
        end
      end
      
      if hastag2?
        V1_V2_TAG_MAPPING.each do |key1, key2|
          @tag2[key2] = @tag[key1] if @tag[key1]
        end
      end
    end
  end
  
  def save_id3v1_changes!
    if hastag1? && @tag1.changed?
      $stderr.puts("Mp3Info.save_id3v1_changes! #{@tag1.version} tag has changed") if $DEBUG
      raise(Mp3InfoError, "file is not writable") unless File.writable?(@filename)
      
      File.open(@filename, 'rb+') do |file|
        file.seek(-ID3::TAGSIZE, File::SEEK_END)
        t = file.read(3)
        if t == 'TAG'
          # replace the current tag
          file.seek(-3, IO::SEEK_CUR)
        else
          # append new tag to end of file
          file.seek(0, File::SEEK_END)
        end
        writable_tag = @tag1.sync_bin
        $stderr.puts("Mp3Info.close #{@tag1.version} [#{writable_tag.inspect}] about to be written at #{file.pos}") if $DEBUG
        file.write(@tag1.sync_bin)
      end
    end
  end

  def update_file_with_changed_id3v2!
    if hastag2?
      if @tag2.changed?
        $stderr.puts "Mp3Info.update_file_with_changed_id3v2! ID3V#{@tag2.version} tag has changed" if $DEBUG
        write_changed_file! { |file| file.write(@tag2.to_bin) unless @tag2.empty? }
      else
        $stderr.puts "Mp3Info.update_file_with_changed_id3v2! ID3V#{@tag2.version} tag is unchanged, not writing file" if $DEBUG
      end
    elsif Mp3Info.hastag2?(@filename)
      $stderr.puts("Mp3Info.update_file_with_changed_id3v2! ID3v2 tag has been eliminated from previously tagged file.") if $DEBUG
      write_changed_file!
    end
  end
  
  def write_changed_file!(&block)
    raise(Mp3InfoError, "file is not writable") unless File.writable?(@filename)
    
    if $DEBUG
      $stderr.puts("Mp3Info.write_changed_file! source file length is #{File.size(@filename)}")
      $stderr.puts("Mp3Info.write_changed_file! source file is [#{File.read(@filename).inspect}]")
    end
    
    tmpfile_path = nil
    File.open(@filename, 'rb+') do |original|
      Tempfile.open('mp3info') do |temporary|
        tmpfile_path = temporary.path
        
        yield temporary if block
        
        $stderr.puts("Mp3Info.write_changed_file! about to call find_next_frame, file.pos=#{original.pos}") if $DEBUG
        header_pos, header = find_next_frame(original)
        original.seek(header_pos)
        $stderr.puts("Mp3Info.write_changed_file! original file is at location #{original.pos}") if $DEBUG
        bufsize = original.stat.blksize || 4096
        while buf = original.read(bufsize)
          temporary.write(buf)
          $stderr.puts("Mp3Info.write_changed_file! wrote #{bufsize} bytes of the original file to #{tmpfile_path}") if $DEBUG
        end
      end
    end
    File.rename(tmpfile_path, @filename)
  end
  
  def time_string
    if has_xing_header?
      length = (26 / 1000.0) * @xing_header.frames
      seconds = length.floor % 60
      minutes = length.floor / 60
      leftover = @xing_header.frames % (1000 / 26)
      time_string = "%d:%02d/%02d" % [minutes, seconds, leftover]
    else
      length = ((@streamsize << 3) / 1000.0) / bitrate
      if hastag2? && @tag2['TLEN']
        tlen = (@tag2['TLEN'].is_a?(Array) ? @tag2['TLEN'].last : @tag2['TLEN']).value.to_i / 1000
        percent_diff = ((length.to_i - tlen) / tlen.to_f)
        if percent_diff.abs > 0.05
          length = tlen
        end
      end
      minutes = length.floor / 60
      seconds = length.round % 60
      time_string = "%d:%02d   " % [minutes, seconds]
    end
    
    time_string
  end
  
  # This method assumes that the file pointer is at the beginning of a frame.
  #
  # It returns either the next frame or the remainder of the stream.
  def read_next_frame(file)
    cur_pos = file.pos
    file.seek(1, IO::SEEK_CUR)
    
    frame_size = 0
    
    begin
      next_pos, data = find_next_frame(file)
      frame_size = next_pos - cur_pos
    rescue Mp3InfoError
      frame_size = file.stat.size - cur_pos
    end
    
    file.seek(cur_pos)
    file.read(frame_size)
  end
  
  def find_next_frame(file)
    header_pos = 0
    header = nil
    
    # make sure we've got the sync pattern, let the MPEGHeader validity check do the rest
    cur_pos = file.pos
    loop do
      header_pos, header = find_sync(file, cur_pos)
      $stderr.puts("Mp3Info.find_next_frame file.pos is %u, header_pos is %u, header is %#x" % [file.pos, header_pos, header.to_binary_decimal]) if header && $DEBUG
      break if nil == header || valid_mpeg_header?(header)
      cur_pos = header_pos + 1
    end
    
    if header
      return header_pos, header
    else
      raise(Mp3InfoError, "cannot find a valid frame after reading #{file.pos} bytes from #{file.path} of size #{file.stat.size}")
    end
  end
  
  def valid_mpeg_header?(header_string)
    MPEGHeader.new(header_string).valid?
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
end

if $0 == __FILE__
  while filename = ARGV.shift
    begin
      info = Mp3Info.new(filename)
      puts "\n#{File.basename(filename)}     [ #{File.size(filename)} ]"
      puts "-------------------------------------------------------------------------------- "
      puts info
      puts "-------------------------------------------------------------------------------- "
    rescue Mp3InfoError => e
      puts "#{filename}\nERROR: #{e}"
    end
  end
end
