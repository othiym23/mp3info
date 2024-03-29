# encoding: binary
# $Id: mp3info.rb,v 37eef5deb369 2009/03/17 23:04:39 ogd $
# License:: Ruby
# Author:: Forrest L Norvell (mailto:forrest_AT_driftglass_DOT_org)
# Author:: Guillaume Pierronnet (mailto:moumar_AT__rubyforge_DOT_org)
# Website:: http://hg.driftglass.org/
script_path = __FILE__
script_path = File.readlink(script_path) if File.symlink?(script_path)

$: << File.join(File.dirname(script_path), '../lib')

require 'delegate'
require 'fileutils'
require 'mp3info/mpeg_header'
require 'mp3info/xing_header'
require 'mp3info/lame_header'
require 'mp3info/replaygain_info'
require 'mp3info/id3'
require 'mp3info/id3v2'

# ruby -d to display debugging info

# Raised on any kind of error related to ruby-mp3info
class Mp3InfoError < StandardError ; end

class Mp3Info
  # source of write_mpeg_file!, find_next_frame and read_next_frame
  include MPEGFile
  
  VERSION = "0.7-fln"
  
  V1_V2_TAG_MAPPING = { 
    "title"    => "TIT2",
    "artist"   => "TPE1", 
    "album"    => "TALB",
    "year"     => "TYER",
    "tracknum" => "TRCK",
    "comments" => "COMM",
    "genre_s"  => "TCON"
  }

  # MPEG header
  attr_reader :mpeg_header
  
  # Xing header
  attr_reader :xing_header
  
  # LAME header
  attr_reader :lame_header
  
  # replaygain info object
  def replaygain_info
    ReplaygainInfo.new(self)
  end
  
  # bitrate in kbps
  def bitrate
    if has_xing_header? && @xing_header.vbr? && @xing_header.frames > 0 && @mpeg_header.frame_duration > 0
      (@xing_header.bytes / (@xing_header.frames * @mpeg_header.frame_duration * 125)).to_i
    elsif vbr? && defined?(@bitrate) && @bitrate > 0
      @bitrate
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
    @id3v1_tag.update(new_hash)
  end
  
  # id3v2 tag attribute as an ID3V2 object. You can modify it, it will be written when calling
  # "close" method.
  attr_accessor :id3v2_tag

  # the original filename
  attr_reader :filename

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
    if ID3.has_id3v1_tag?(@filename)
      ID3.remove_id3v1_tag!(@filename)
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

    while file.pos < total_bytes do
      # try to read tags first, then read MPEG data
      case file.read(3)
      when 'TAG' # ID3 tag at the beginning of the file (unusual)
        file.seek(-3, IO::SEEK_CUR)
        $stderr.puts("Mp3Info.initialize TAG found at %#010x" % file.pos) if $DEBUG
        @id3v1_tag = ID3.from_io(file)
        $stderr.puts("Mp3Info.initialize ID3 tag is #{@id3v1_tag.inspect}") if $DEBUG
      when 'ID3' # ID3v2 tag
        file.seek(-3, IO::SEEK_CUR)
        $stderr.puts("Mp3Info.initialize ID3 found at %#010x" % file.pos) if $DEBUG
        if has_id3v2_tag?
          @id3v2_tag.merge(ID3V2.from_io(file))
        else
          @id3v2_tag = ID3V2.from_io(file)
        end
      else
        file.seek(-3, IO::SEEK_CUR)
        $stderr.puts("Mp3Info.initialize scanning for MPEG data at %#010x" % file.pos) if $DEBUG
        cur_pos = file.pos
        begin
          $stderr.puts("Mp3Info.initialize about to call find_next_frame at %#010x" % file.pos) if $DEBUG
          header_pos, header_data = find_next_frame(file, cur_pos)
          mpeg_candidate = MPEGHeader.new(header_data)
          @mpeg_header = mpeg_candidate if mpeg_candidate.valid?
          
          if mpeg_candidate.valid?
            $stderr.puts("mpeg header %#010x found at position %#010x (%s)" % [header_data.to_binary_decimal, header_pos, mpeg_candidate.to_s]) if $DEBUG
            file.seek(header_pos)
            cur_frame = read_next_frame(file, mpeg_candidate.frame_size)
            $stderr.puts("Current frame is %#06x bytes (requested %#06x)" % [cur_frame.size, mpeg_candidate.frame_size]) if $DEBUG
            
            xing_candidate = XingHeader.new(cur_frame)
            @xing_header = xing_candidate if xing_candidate.valid?
            $stderr.puts("Xing header found, is [#{@xing_header.to_s}]") if $DEBUG && has_xing_header?
            
            lame_candidate = LAMEHeader.new(cur_frame)
            @lame_header = lame_candidate if lame_candidate.valid?
            $stderr.puts("LAME header found, is [#{@lame_header.inspect}]") if $DEBUG && has_lame_header?
            break # we're done trying to read candidates
          end
        rescue MPEGFile::MPEGFileError
          $stderr.puts("Mp3Info.initialize guesses there's no MPEG frames in this file.") if $DEBUG
          file.seek(cur_pos)
          break
        end
      end
      $stderr.puts("File position is #{"%#010x" % file.pos}") if $DEBUG
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
        if tlen > 0
          percent_diff = ((@length.to_i - tlen) / tlen.to_f)
          if percent_diff.abs > 0.05
            @vbr = true
            @bitrate = (@streamsize / tlen) / 1024
          end
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
          @id3v1_tag.update(ID3.from_io(file))
        else
          @id3v1_tag = ID3.from_io(file)
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
  def Mp3Info.open(filename)
    m = self.new(filename)
    ret = nil
    if block_given?
      begin
        ret = yield m
      ensure
        m.close
      end
    else
      ret = m
    end
    ret
  end
  
  # write to another filename at close()
  def rename(new_filename)
    @filename = new_filename
  end

  # inspect inside Mp3Info
  def to_s
    if has_mpeg_header?
      time = "Time: #{duration_string}"
      type = has_mpeg_header? ? @mpeg_header.version_string : "NO AUDIO"
      properties = " [ #{vbr? ? '~' : ''}#{bitrate}kbps @ #{"%g" % (@mpeg_header.sample_rate / 1000.0)}kHz - #{@mpeg_header.mode}#{@mpeg_header.error_protected? ? " +E" : ""} ]"
      
      # try to always keep the string representation at 80 characters
      "#{time}#{" " * [(18 - time.size), 0].max}#{type}#{" " * [(62 - (type.size + properties.size)), 0].max}#{properties}"
    else
      "NO AUDIO FOUND"
    end
  end
  
  def description
    file_name_string = File.basename(filename)
    file_size_string= " [ #{File.size(filename).octet_units} ]"
    
    out_string =  "\n#{file_name_string}#{' ' * [(80 - (file_name_string.size + file_size_string.size)), 0].max}#{file_size_string}\n"
    out_string << "--------------------------------------------------------------------------------\n"
    out_string << to_s
    out_string << "\n--------------------------------------------------------------------------------\n"
  end
  
  def duration_string
    if has_xing_header?
      time     = (@mpeg_header.frame_duration * @xing_header.frames).floor
      seconds  = time % 60
      time    /= 60
      minutes  = time % 60
      hours    = time / 60
      leftover = (@xing_header.frames % (1 / @mpeg_header.frame_duration)).round
      
      if hours > 0
        "%d:%02d:%02d/%02d" % [hours, minutes, seconds, leftover]
      else
        "%d:%02d/%02d" % [minutes, seconds, leftover]
      end
    elsif has_mpeg_header?
      time = (@streamsize * @mpeg_header.frame_duration) / @mpeg_header.frame_size
      if has_id3v2_tag? && @id3v2_tag['TLEN'] && @id3v2_tag['TLEN'].value.to_i > 0
        tlen = (@id3v2_tag['TLEN'].is_a?(Array) ? @id3v2_tag['TLEN'].last : @id3v2_tag['TLEN']).value.to_i / 1000
        percent_diff = ((time.to_i - tlen) / tlen.to_f)
        if percent_diff.abs > 0.05
          time = tlen
        end
      end
      time = time.round
      
      seconds  = time % 60
      time    /= 60
      minutes  = time % 60
      hours    = time / 60
      
      if hours > 0
        "%d:%02d:%02d" % [hours, minutes, seconds]
      else
        "%d:%02d" % [minutes, seconds]
      end
    else
      "-"
    end
  end
  
  private
  
  # Internal semantics are a little different than what is exposed -- casual
  # users should only think the file has an MP3 tag when the tag has contents,
  # but the universal tag relies upon not stomping on the empty tag if it
  # exists.
  def actually_has_id3v2_tag?
    nil != defined?(@id3v2_tag) && nil != @id3v2_tag
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
      @id3v1_tag.to_file(@filename)
    end
  end

  def update_file_with_changed_id3v2!
    if has_id3v2_tag?
      if @id3v2_tag.changed?
        $stderr.puts "Mp3Info.update_file_with_changed_id3v2! ID3V#{@id3v2_tag.version} tag has changed" if $DEBUG
        write_mpeg_file!(@filename) { |file| file.write(@id3v2_tag.to_bin) unless @id3v2_tag.empty? }
      else
        $stderr.puts "Mp3Info.update_file_with_changed_id3v2! ID3V#{@id3v2_tag.version} tag is unchanged, not writing file" if $DEBUG
      end
    elsif ID3V2.has_id3v2_tag?(@filename)
      $stderr.puts("Mp3Info.update_file_with_changed_id3v2! ID3v2 tag has been eliminated from previously tagged file.") if $DEBUG
      write_mpeg_file!(@filename)
    end
  end
end
