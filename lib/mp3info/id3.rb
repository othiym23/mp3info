# encoding: binary
require 'delegate'
require 'mp3info/compatibility_utils'

class ID3Error < StandardError ; end

class ID3 < DelegateClass(Hash)
  VERSION_1   = "ID3"
  VERSION_1_1 = "ID3v1.1"
  
  TAGSIZE = 128
  
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
    "New Wave", "Psychedelic", "Rave", "Showtunes", "Trailer", "Lo-Fi",
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
  
  # expose the version of the tag
  attr_reader :version
  
  def ID3.has_id3v1_tag?(filename)
    File.open(filename) { |f|
      f.seek(-TAGSIZE, File::SEEK_END)
      f.read(3) == 'TAG'
    }
  end
  
  def ID3.remove_id3v1_tag!(filename)
    if has_id3v1_tag?(filename)
      File.truncate(filename, File.size(filename) - TAGSIZE)
    end
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
    valid_header? && valid_major_version?
  end
  
  def valid_header?
    @raw_tag[0..2] == 'TAG'
  end
  
  def valid_major_version?
    [VERSION_1, VERSION_1_1].include?(version)
  end
  
  def ID3.from_file(filename)
    if has_id3v1_tag?(filename)
      File.open(filename) do |file|
        file.seek(-TAGSIZE, IO::SEEK_END)
        ID3.from_io(file)
      end
    else
      raise(ID3Error, "No ID3 tag found in #{filename}")
    end
  end
  
  def to_file(filename)
    if File.exists?(filename)
      # updating an existing tagged file
      File.open(filename, 'rb+') do |file|
        file.seek(-TAGSIZE, IO::SEEK_END)
        t = file.read(3)
        if t == 'TAG'
          # replace the current tag
          file.seek(-3, IO::SEEK_CUR)
        else
          # append new tag to end of file
          file.seek(0, IO::SEEK_END)
        end
        $stderr.puts("ID3.to_file #{version} [#{sync_bin.inspect}] about to be written at #{file.pos}") if $DEBUG
        file.write(sync_bin)
      end
    else
      # dumping a tag in a random file
      File.open(filename, 'w') do |file|
        file.write(sync_bin)
      end
    end
  end
  
  # assumes io.pos is at the beginning of the ID3 tag
  def ID3.from_io(io)
    remaining_bytes = io.stat.size - io.pos
    
    if remaining_bytes >= ID3::TAGSIZE
      raw_tag = io.read(ID3::TAGSIZE)
      
      id3 = ID3.new
      id3.from_bin(raw_tag)
    else
      $stderr.puts("file looks like it has an ID3 tag at the start, but isn't big enough to contain one.")
      io.seek(0)
    end
    
    id3
  end
  
  def from_bin(string)
    $stderr.puts("ID3.from_bin(string=[#{string.inspect}])") if $DEBUG
    @hash["title"], @hash["artist"], @hash["album"],
     year_t, raw_comments, @hash["genre"] = string[3..-1].unpack('A30A30A30A4a30C')
    
    @hash["year"] = year_t unless year_t == 0
    @hash["genre_s"] = GENRES[@hash["genre"]] || "Unknown" # as per spec
    
    # The sole difference between ID3v1.1 and ID3v1 is that the former has the
    # track number tucked in as an unsigned byte at the end of the comments field.
    #
    # There is probably a better way to make this comparison work in both
    # ruby 1.9 and previous versions, but for now, this works.
    if raw_comments[-2].to_ordinal == 0 && raw_comments[-1].to_ordinal > 0
      @version = VERSION_1_1
      @hash["tracknum"] = raw_comments[-1].to_ordinal
      # remove the last character, which contains the track number
      raw_comments.chop!
    else
      @version = VERSION_1
    end
    @hash["comments"] = raw_comments.strip
    
    self
  end
  
  def sync_bin
    @raw_tag = to_bin
    @hash_orig.update(@hash)
    @raw_tag
  end
  
  def to_bin
    if changed?
      @version = VERSION_1_1 unless defined? @version
      case @version
      when VERSION_1
        attrs = 
          [
            @hash['title']    || '',
            @hash['artist']   || '',
            @hash['album']    || '',
            @hash['year']     || '',
            @hash['comments'] || '',
            @hash['genre']    || 255
          ]
        "TAG#{attrs.pack('A30A30A30A4A30C')}"
      when VERSION_1_1
        attrs = 
          [
            @hash['title']    || '',
            @hash['artist']   || '',
            @hash['album']    || '',
            @hash['year']     || '',
            @hash['comments'] || '',
            @hash['tracknum'] || 0,
            @hash['genre']    || 255
          ]
        "TAG#{attrs.pack('A30A30A30A4a29CC')}"
      else
        raise(ID3Error, "Unrecognized version #{@version}")
      end
    else
      @raw_tag
    end
  end
end