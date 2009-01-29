# $Id: mp3info.rb,v 8304983d10ad 2009/01/29 22:20:51 ogd $
# License:: Ruby
# Author:: Guillaume Pierronnet (mailto:moumar_AT__rubyforge_DOT_org)
# Website:: http://ruby-mp3info.rubyforge.org/
script_path = __FILE__
script_path = File.readlink(script_path) if File.symlink?(script_path)

$: << File.join(File.dirname(script_path), '../lib')

require "delegate"
require "fileutils"
require "mp3info/extension_modules"
require "mp3info/mpeg_header"
require "mp3info/id3v2"

# ruby -d to display debugging infos

# Raised on any kind of error related to ruby-mp3info
class Mp3InfoError < StandardError ; end

class Mp3InfoInternalError < StandardError #:nodoc:
end

class Mp3Info
  VERSION = "0.6"

  GENRES = [
    "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk",
    "Grunge", "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies",
    "Other", "Pop", "R&B", "Rap", "Reggae", "Rock",
    "Techno", "Industrial", "Alternative", "Ska", "Death Metal", "Pranks",
    "Soundtrack", "Euro-Techno", "Ambient", "Trip-Hop", "Vocal", "Jazz+Funk",
    "Fusion", "Trance", "Classical", "Instrumental", "Acid", "House",
    "Game", "Sound Clip", "Gospel", "Noise", "AlternRock", "Bass",
    "Soul", "Punk", "Space", "Meditative", "Instrumental Pop", "Instrumental Rock",
    "Ethnic", "Gothic", "Darkwave", "Techno-Industrial", "Electronic", "Pop-Folk",
    "Eurodance", "Dream", "Southern Rock", "Comedy", "Cult", "Gangsta",
    "Top 40", "Christian Rap", "Pop/Funk", "Jungle", "Native American", "Cabaret",
    "New Wave", "Psychadelic", "Rave", "Showtunes", "Trailer", "Lo-Fi",
    "Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", "Musical",
    "Rock & Roll", "Hard Rock", "Folk", "Folk/Rock", "National Folk", "Swing",
    "Fast-Fusion", "Bebob", "Latin", "Revival", "Celtic", "Bluegrass", "Avantgarde",
    "Gothic Rock", "Progressive Rock", "Psychedelic Rock", "Symphonic Rock", "Slow Rock", "Big Band",
    "Chorus", "Easy Listening", "Acoustic", "Humour", "Speech", "Chanson",
    "Opera", "Chamber Music", "Sonata", "Symphony", "Booty Bass", "Primus",
    "Porn Groove", "Satire", "Slow Jam", "Club", "Tango", "Samba",
    "Folklore", "Ballad", "Power Ballad", "Rhythmic Soul", "Freestyle", "Duet",
    "Punk Rock", "Drum Solo", "A capella", "Euro-House", "Dance Hall",
    "Goa", "Drum & Bass", "Club House", "Hardcore", "Terror",
    "Indie", "BritPop", "NegerPunk", "Polsk Punk", "Beat",
    "Christian Gangsta", "Heavy Metal", "Black Metal", "Crossover", "Contemporary C",
    "Christian Rock", "Merengue", "Salsa", "Thrash Metal", "Anime", "JPop",
    "SynthPop" ]

  TAGSIZE = 128
  #MAX_FRAME_COUNT = 6  #number of frame to read for encoder detection
  V1_V2_TAG_MAPPING = { 
    "title"    => "TIT2",
    "artist"   => "TPE1", 
    "album"    => "TALB",
    "year"     => "TYER",
    "tracknum" => "TRCK",
    "comments" => "COMM",
    "genre_s"  => "TCON"
  }


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
    @bitrate ||= false
    if @bitrate
      @bitrate
    elsif vbr
      (((@streamsize / @frames) * samplerate) / 144) >> 10
    else
      @mpeg_header.bitrate
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

  # id3v1 tag as a Hash. You can modify it, it will be written when calling
  # "close" method.
  attr_accessor :tag1

  # id3v2 tag attribute as an ID3v2 object. You can modify it, it will be written when calling
  # "close" method.
  attr_accessor :tag2

  # the original filename
  attr_reader :filename

  # Moved hastag1? and hastag2? to be booleans
  attr_reader :hastag1, :hastag2

  # expose the raw size of the tag for quality-checking purposes
  attr_reader :tag_size
  
  # Test the presence of an id3v1 tag in file +filename+
  def self.hastag1?(filename)
    File.open(filename) { |f|
      f.seek(-TAGSIZE, File::SEEK_END)
      f.read(3) == "TAG"
    }
  end

  # Test the presence of an id3v2 tag in file +filename+
  def self.hastag2?(filename)
    File.open(filename) { |f|
      f.read(3) == "ID3"
    }
  end


  # Remove id3v1 tag from +filename+
  def self.removetag1(filename)
    if self.hastag1?(filename)
      newsize = File.size(filename) - TAGSIZE
      File.open(filename, "rb+") { |f| f.truncate(newsize) }
    end
  end
  
  # Remove id3v2 tag from +filename+
  def self.removetag2(filename)
    self.open(filename) do |mp3|
      mp3.tag2.clear
    end
  end

  # Instantiate a new Mp3Info object with name +filename+
  def initialize(filename)
    $stderr.puts("#{self.class}::new() does not take block; use #{self.class}::open() instead") if block_given?

    @filename = filename
    @hastag1 = false
    
    @tag1 = {}
    @tag1.extend(HashKeys)

    @tag2 = ID3v2.new

    @file = File.new(filename, "rb")
    @file.extend(Mp3FileMethods)
    
    return unless File.stat(filename).size? #FIXME

    begin
      @tag_size = parse_tags
      @tag1_orig = @tag1.dup

      @tag = {}

      if hastag1?
        @tag = @tag1.dup
      end

      if hastag2?
        @tag = {}
        #creation of a sort of "universal" tag, regardless of the tag version
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

      @tag.extend(HashKeys)
      @tag_orig = @tag.dup

      ### extracts MPEG info from MPEG header and stores it in the hash @mpeg
      ###  head (fixnum) = valid 4 byte MPEG header
      if @file && tag_size && @file.stat.size > tag_size
        @mpeg_header = parse_mpeg_header

        # the seek offsets below are highly magical and need more documentation
        if 1 == mpeg_version
          if @mpeg_header.mode_extension == (MPEGHeader::MODE_EXTENSION_BANDS_4_TO_31 | MPEGHeader::MODE_EXTENSION_BANDS_8_TO_31)
            @file.seek(17, IO::SEEK_CUR)
          else
            @file.seek(32, IO::SEEK_CUR)
          end
        else
          if @mpeg_header.mode_extension == (MPEGHeader::MODE_EXTENSION_BANDS_4_TO_31 | MPEGHeader::MODE_EXTENSION_BANDS_8_TO_31)
            @file.seek(9, IO::SEEK_CUR)
          else
            @file.seek(17, IO::SEEK_CUR)
          end
        end
        
        # default to assuming the file is CBR unless the Xing tag indicates otherwise
        @vbr = false
        
        vbr_head = @file.read(4)
        if vbr_head == "Xing"
          puts "Xing header (VBR) detected" if $DEBUG
          flags = @file.get32bits
          @streamsize = @frames = 0
          flags[1] == 1 and @frames = @file.get32bits
          flags[2] == 1 and @streamsize = @file.get32bits 
          puts "#{@frames} frames" if $DEBUG
          raise(Mp3InfoError, "bad VBR header for #{filename}") if @frames.zero?
          # currently this just skips the TOC entries if they're found
          @file.seek(100, IO::SEEK_CUR) if flags[0] == 1
          @vbr_quality = @file.get32bits if flags[3] == 1
          @length = (26/1000.0)*@frames
          @vbr = true
        else
          # for cbr, calculate duration with the given bitrate
          @streamsize = @file.stat.size - (@hastag1 ? TAGSIZE : 0) - (@tag2.valid? ? @tag2.io_position : 0)
          @length = ((@streamsize << 3)/1000.0)/bitrate
          if @tag2.TLEN
            # but if another duration is given and it isn't close (within 5%)
            #  assume the mp3 is vbr and go with the given duration
            tlen = (@tag2.TLEN.is_a?(Array) ? @tag2.TLEN.last : @tag2.TLEN).value.to_i / 1000
            percent_diff = ((@length.to_i-tlen)/tlen.to_f)
            if percent_diff.abs > 0.05
              # without the xing header, this is the best guess without reading
              #  every single frame
              @vbr = true
              @length = tlen
              @bitrate = (@streamsize / bitrate) >> 10
            end
          end
        end
      end
    ensure
      @file.close
    end
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

  # Remove id3v1 from mp3
  def removetag1
    if hastag1?
      newsize = @file.stat.size(filename) - TAGSIZE
      @file.truncate(newsize)
      @tag1.clear
    end
    self
  end
  
  def removetag2
    @tag2.clear
  end

  # Does the file has an id3v1 or v2 tag?
  def hastag?
    @hastag1 or @tag2.valid?
  end

  # Does the file has an id3v1 tag?
  def hastag1?
    @hastag1
  end

  # Does the file has an id3v2 tag?
  def hastag2?
    @tag2.valid?
  end

  def tag2_len
    @tag2.valid? ? @tag2.tag2_len : 0
  end
  
  # write to another filename at close()
  def rename(new_filename)
    @filename = new_filename
  end

  # Flush pending modifications to tags and close the file
  def close
    puts "close" if $DEBUG
    if @tag != @tag_orig
      puts "@tag has changed" if $DEBUG
      @tag.each do |k, v|
        @tag1[k] = v
      end
      
      V1_V2_TAG_MAPPING.each do |key1, key2|
        @tag2[key2] = ID3V24::Frame.create_frame(key2, @tag[key1]) if @tag[key1]
      end
    end

    if @tag1 != @tag1_orig && @tag1_orig
      puts "@tag1 has changed" if $DEBUG
      raise(Mp3InfoError, "file is not writable") unless File.writable?(@filename)
      @tag1_orig.update(@tag1)
      puts "@tag1_orig: #{@tag1_orig.inspect}" if $DEBUG
      File.open(@filename, 'rb+') do |file|
        file.seek(-TAGSIZE, File::SEEK_END)
        t = file.read(3)
        if t != 'TAG'
          #append new tag
          file.seek(0, File::SEEK_END)
          file.write('TAG')
        end
        str = [
          @tag1_orig["title"]||"",
          @tag1_orig["artist"]||"",
          @tag1_orig["album"]||"",
          ((@tag1_orig["year"] != 0) ? ("%04d" % @tag1_orig["year"].to_i) : "\0\0\0\0"),
          @tag1_orig["comments"]||"",
          0,
          @tag1_orig["tracknum"]||0,
          @tag1_orig["genre"]||255
          ].pack("Z30Z30Z30Z4Z28CCC")
        file.write(str)
      end
    end

    if @tag2.changed?
      puts "@tag2 has changed" if $DEBUG
      raise(Mp3InfoError, "file is not writable") unless File.writable?(@filename)
      tempfile_name = nil
      File.open(@filename, 'rb+') do |file|
        
        #if tag2 already exists, seek to end of it
        if @tag2.valid?
          file.seek(@tag2.io_position)
        end
        tempfile_name = @filename + ".tmp"
        File.open(tempfile_name, "wb") do |tempfile|
          unless @tag2.empty?
            tempfile.write("ID3")
            tempfile.write(@tag2.to_bin)
          end

          bufsiz = file.stat.blksize || 4096
          while buf = file.read(bufsiz)
            tempfile.write(buf)
          end
        end
      end
      File.rename(tempfile_name, @filename)
    end
    @file = nil
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

  def time_string
    if @vbr
      length = (26 / 1000.0) * @frames
      seconds = length.floor % 60
      minutes = length.floor / 60
      leftover = @frames % (1000 / 26)
      time_string = "%d:%02d/%02d" % [minutes, seconds, leftover]
    else
      length = ((@streamsize << 3) / 1000.0) / bitrate
      if @tag2.TLEN
        tlen = (@tag2.TLEN.is_a?(Array) ? @tag2.TLEN.last : @tag2.TLEN).value.to_i / 1000
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
  
  def parse_mpeg_header
    found = false
    header = nil
    
    5.times do
      header = MPEGHeader.new(find_next_frame.to_binary_string)
      next unless header.valid?
      
      found = true
      break
    end
    
    raise(Mp3InfoError, "Cannot find good frame in #{filename}") unless found
    
    header
  end
  
  ### parses the id3 tags of the currently open @file
  def parse_tags
    return if @file.stat.size < TAGSIZE  # file is too small
    @file.seek(0)
    f3 = @file.read(3)
    gettag1 if f3 == "TAG"  # v1 tag at beginning
    @tag2.from_io(@file) if f3 == "ID3"  # v2 tag at beginning
      
    unless @hastag1         # v1 tag at end
        # this preserves the file pos if tag2 found, since gettag2 leaves
        #  the file at the best guess as to the first MPEG frame
        pos = (@tag2.valid? ? @file.pos : 0)
        # seek to where id3v1 tag should be
        @file.seek(-TAGSIZE, IO::SEEK_END) 
        gettag1 if @file.read(3) == "TAG"
        @file.seek(pos)
    end
    
    pos
  end

  ### reads in id3 field strings, stripping out non-printable chars
  ###  len (fixnum) = number of chars in field
  ### returns string
  def read_id3_string(len)
    #FIXME handle unicode strings
    #return @file.read(len)
    s = ""
    len.times do
      c = @file.getc
      # only append printable characters
      s << c if c >= 32 and c < 254
    end
    return s.strip
  end
  
  ### gets id3v1 tag information from @file
  ### assumes @file is pointing to char after "TAG" id
  def gettag1
    @hastag1 = true
    @tag1["title"] = read_id3_string(30)
    @tag1["artist"] = read_id3_string(30)
    @tag1["album"] = read_id3_string(30)
    year_t = read_id3_string(4).to_i
    @tag1["year"] = year_t unless year_t == 0
    comments = @file.read(30)
    if comments[-2] == 0
      @tag1["tracknum"] = comments[-1].to_i
      comments.chop! #remove the last char
    end
    @tag1["comments"] = comments.strip
    @tag1["genre"] = @file.getc
    @tag1["genre_s"] = GENRES[@tag1["genre"]] || ""
  end

  ### reads through @file from current pos until it finds a valid MPEG header
  ### returns the MPEG header as FixNum
  def find_next_frame
    # @file will now be sitting at the best guess for where the MPEG frame is.
    # It should be at byte 0 when there's no id3v2 tag.
    # It should be at the end of the id3v2 tag or the zero padding if there
    #   is a id3v2 tag.

    #dummyproof = @file.stat.size - @file.pos => WAS TOO MUCH
    dummyproof = [ @file.stat.size - @file.pos, 2000000 ].min
    dummyproof.times do |i|
      if @file.getc == 0xff
        data = @file.read(3)
        raise(Mp3InfoError, "invalid frame in #{@file.path}") if @file.eof?
        head = 0xff000000 + (data[0] << 16) + (data[1] << 8) + data[2]
        if check_head(head)
            return head
        else
            @file.seek(-3, IO::SEEK_CUR)
        end
      end
    end
    raise Mp3InfoError, "cannot find a valid frame after reading #{dummyproof} bytes from #{@file.path}"
  end

  ### checks the given header to see if it is valid
  ###  head (fixnum) = 4 byte value to test for MPEG header validity
  ### returns true if valid, false if not
  def check_head(head)
    return false if head & 0xffe00000 != 0xffe00000    # 11 bit MPEG frame sync
    return false if head & 0x00060000 == 0x00060000    #  2 bit layer type
    return false if head & 0x0000f000 == 0x0000f000    #  4 bit bitrate
    return false if head & 0x0000f000 == 0x00000000    #        free format bitstream
    return false if head & 0x00000c00 == 0x00000c00    #  2 bit frequency
    return false if head & 0xffff0000 == 0xfffe0000
    true
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
    puts
  end
end
