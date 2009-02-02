require "delegate"

class ID3 < DelegateClass(Hash)
  VERSION_1   = "ID3"
  VERSION_1_1 = "ID3v1.1"
  
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
  
  def initialize(tag_string = "")
    # initialize the delegated hash
    @hash = {}
    super(@hash)
    
    @hash["title"], @hash["artist"], @hash["album"],
     year_t, raw_comments, @hash["genre"] = tag_string[3..-1].unpack('A30A30A30A4a30C')
    
    @hash["year"] = year_t unless year_t == 0
    @hash["genre_s"] = GENRES[@hash["genre"]] || "Unknown" # as per spec
    
    # the sole difference between ID3v1.1 and ID3v1 is that the former has the
    # track number tucked in as an unsigned byte at the end of the comments field
    if raw_comments[-2] == 0 && raw_comments[-1] > 0
      @version = VERSION_1_1
      @hash["tracknum"] = raw_comments[-1].to_i
      raw_comments.chop! # remove the last char. which contains the genre
    else
      @version = VERSION_1
    end
    @hash["comments"] = raw_comments.strip
  end
end