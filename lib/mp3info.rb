# $Id: mp3info.rb,v ff91be31cf9a 2009/02/10 18:14:30 ogd $
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
require 'mp3info/lame_header'
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
  
  # LAME header
  attr_reader :lame_header
  
  # bitrate in kbps
  def bitrate
    if has_xing_header?
      (((@xing_header.bytes / @xing_header.frames) * @mpeg_header.sample_rate) / 144) >> 10
    elsif has_mpeg_header?
      @mpeg_header.bitrate
    else
      0
    end
  end

  # variable bitrate => true or false
  def vbr?
    (has_xing_header? && xing_header.vbr?) || (defined?(@vbr) && @vbr)
  end

  # length in seconds as a Float
  attr_reader :length

  # a sort of "universal" tag, regardless of the tag version, 1 or 2, with the same keys as @id3v1_tag
  # this tag has priority over @id3v1_tag and @id3v2_tag when writing the tag with #close
  attr_reader :tag

  # The ID3 tag is a class that acts as a hash. You can update it and it will
  # be written out when the file is closed.
  attr_reader :id3v1_tag
  
  def id3v1_tag=(new_hash)
    @id3v1_tag = ID3.new unless has_id3v1_tag?
    @id3v1_tag.update(new_hash)
  end
  
  # id3v2 tag attribute as an ID3V2 object. You can modify it, it will be written when calling
  # "close" method.
  attr_accessor :id3v2_tag

  # the original filename
  attr_reader :filename

  def self.has_id3v1_tag?(filename)
    File.open(filename) { |f|
      f.seek(-ID3::TAGSIZE, File::SEEK_END)
      f.read(3) == "TAG"
    }
  end

  def self.has_id3v2_tag?(filename)
    File.open(filename) { |f|
      f.read(3) == "ID3"
    }
  end

  def self.remove_id3v1_tag(filename)
    if self.has_id3v1_tag?(filename)
      newsize = File.size(filename) - ID3::TAGSIZE
      File.open(filename, "rb+") { |f| f.truncate(newsize) }
    end
  end
  
  def self.remove_id3v2_tag(filename)
    self.open(filename) do |mp3|
      mp3.id3v2_tag = nil
    end
  end
  
  def has_universal_tag?
    nil != defined?(@tag)
  end

  def has_id3v1_tag?
    nil != defined?(@id3v1_tag) && nil != @id3v1_tag && @id3v1_tag.valid? && @id3v1_tag.size > 0
  end

  def has_id3v2_tag?
    actually_has_id3v2_tag? && @id3v2_tag.size > 0
  end
  
  def has_mpeg_header?
    nil != defined?(@mpeg_header) && nil != @mpeg_header
  end
  
  def has_xing_header?
    nil != defined?(@xing_header) && nil != @xing_header
  end
  
  def has_lame_header?
    nil != defined?(@lame_header) && nil != @lame_header
  end
  
  def remove_id3v1_tag
    if Mp3Info.has_id3v1_tag?(@filename)
      newsize = File.size(@filename) - ID3::TAGSIZE
      $stderr.puts("Mp3Info.remove_id3v1_tag has ID3v1 tag, file will have new size #{newsize}.") if $DEBUG
      File.truncate(@filename, newsize)
    end
    
    if has_id3v1_tag?
      @id3v1_tag = nil
    end
  end
  
  def remove_id3v2_tag
    @id3v2_tag.clear
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
      @id3v1_tag = load_id3_1_tag(file)
      $stderr.puts("Mp3Info.initialize ID3 tag is #{@id3v1_tag.inspect}") if $DEBUG
    when 'ID3' # ID3v2 tag
      $stderr.puts("Mp3Info.initialize ID3 found at beginning of file") if $DEBUG
      file.seek(-3, IO::SEEK_CUR)
      @id3v2_tag = load_id3_2_tag(file)
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
      $stderr.puts("MPEG header found, is [#{@mpeg_header.inspect}]") if $DEBUG && has_mpeg_header?
      
      file.seek(header_pos)
      cur_frame = read_next_frame(file)
      xing_candidate = XingHeader.new(cur_frame)
      @xing_header = xing_candidate if xing_candidate.valid?
      $stderr.puts("Xing header found, is [#{@xing_header.to_s}]") if $DEBUG && has_xing_header?
      
      lame_candidate = LAMEHeader.new(cur_frame)
      @lame_header = lame_candidate if lame_candidate.valid?
      $stderr.puts("LAME header found, is [#{@lame_header.inspect}]") if $DEBUG && has_lame_header?
    rescue Mp3InfoError
      $stderr.puts("Mp3Info.initialize guesses there's no MPEG frames in this file.") if $DEBUG
      file.seek(cur_pos)
    end
    
    #
    # calculate the CBR bitrate, streamsize, length
    #
    if has_mpeg_header? && !has_xing_header?
      # for cbr, calculate duration with the given bitrate
      @streamsize = file.stat.size - (has_id3v1_tag? ? ID3::TAGSIZE : 0) - ((has_id3v2_tag? ? (@id3v2_tag.tag_length + 10) : 0))
      @length = ((@streamsize << 3) / 1000.0) / bitrate
      if has_id3v2_tag? && @id3v2_tag['TLEN']
        # but if another duration is given and it isn't close (within 5%)
        #  assume the mp3 is vbr and go with the given duration
        tlen = (@id3v2_tag['TLEN'].is_a?(Array) ? @id3v2_tag['TLEN'].last : @id3v2_tag['TLEN']).value.to_i / 1000
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
        if has_id3v1_tag?
          @id3v1_tag.update(load_id3_1_tag(file))
        else
          @id3v1_tag = load_id3_1_tag(file)
        end
      end
    end
    
    file.close
    
    load_universal_tag!
    
    if !(has_id3v1_tag? || has_id3v2_tag? || has_mpeg_header? || has_xing_header?)
      raise(Mp3InfoError, "There was no useful metadata in #{@filename}, are you sure it's an MP3?")
    end
    
    # there should always be tags available for convenience
    @id3v1_tag = ID3.new if nil == defined? @id3v1_tag
    @id3v2_tag = ID3V2.new if nil == defined? @id3v2_tag
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
    type = "MPEG#{@mpeg_header.version} Layer #{@mpeg_header.layer}"
    properties = "[ #{vbr? ? "~" : ""}#{bitrate}kbps @ #{@mpeg_header.sample_rate / 1000.0}kHz - #{@mpeg_header.mode} ]#{@mpeg_header.error_protection ? " +error" : ""}"
    
    # try to always keep the string representation at 80 characters
    "#{time}#{" " * (18 - time.size)}#{type}#{" " * (62 - (type.size + properties.size))}#{properties}"
  end

  private
  
  # Internal semantics are a little different than what is exposed -- casual
  # users should only think the file has an MP3 tag when the tag has contents,
  # but the universal tag relies upon not stomping on the empty tag if it
  # exists.
  def actually_has_id3v2_tag?
    nil != defined?(@id3v2_tag) && nil != @id3v2_tag && @id3v2_tag.valid?
  end
  
  def load_universal_tag!
    @tag = {}
    
    if has_id3v1_tag?
      @tag = @id3v1_tag.dup
    end
    
    if actually_has_id3v2_tag?
      @tag = {}
      V1_V2_TAG_MAPPING.each do |key1, key2| 
        t2 = @id3v2_tag[key2]
        next unless t2
        @tag[key1] = t2.is_a?(Array) ? t2.first.value : t2.value

        if key1 == "tracknum"
          val = @id3v2_tag[key2].is_a?(Array) ? @id3v2_tag[key2].first.value : @id3v2_tag[key2].value
          @tag[key1] = val.to_i
        end
      end
    end
    
    @tag_orig = @tag.dup
  end
  
  def prepare_universal_tag!
    if has_universal_tag? && @tag != @tag_orig
      $stderr.puts("Mp3Info.prepare_universal_tag! universal tag has changed") if $DEBUG
      if !(has_id3v1_tag? || actually_has_id3v2_tag?)
        @id3v2_tag = ID3V2.new
      end
      
      if has_id3v1_tag?
        @tag.each do |k, v|
          @id3v1_tag[k] = v
        end
      end
      
      if actually_has_id3v2_tag?
        V1_V2_TAG_MAPPING.each do |key1, key2|
          @id3v2_tag[key2] = @tag[key1] if @tag[key1]
        end
      end
    end
  end
  
  def save_id3v1_changes!
    if has_id3v1_tag? && @id3v1_tag.changed?
      $stderr.puts("Mp3Info.save_id3v1_changes! #{@id3v1_tag.version} tag has changed") if $DEBUG
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
        writable_tag = @id3v1_tag.sync_bin
        $stderr.puts("Mp3Info.close #{@id3v1_tag.version} [#{writable_tag.inspect}] about to be written at #{file.pos}") if $DEBUG
        file.write(@id3v1_tag.sync_bin)
      end
    end
  end

  def update_file_with_changed_id3v2!
    if has_id3v2_tag?
      if @id3v2_tag.changed?
        $stderr.puts "Mp3Info.update_file_with_changed_id3v2! ID3V#{@id3v2_tag.version} tag has changed" if $DEBUG
        write_changed_file! { |file| file.write(@id3v2_tag.to_bin) unless @id3v2_tag.empty? }
      else
        $stderr.puts "Mp3Info.update_file_with_changed_id3v2! ID3V#{@id3v2_tag.version} tag is unchanged, not writing file" if $DEBUG
      end
    elsif Mp3Info.has_id3v2_tag?(@filename)
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
      if has_id3v2_tag? && @id3v2_tag['TLEN']
        tlen = (@id3v2_tag['TLEN'].is_a?(Array) ? @id3v2_tag['TLEN'].last : @id3v2_tag['TLEN']).value.to_i / 1000
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
