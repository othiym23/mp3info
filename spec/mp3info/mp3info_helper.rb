$:.unshift("lib/")

require 'base64'
require 'mp3info'

module Mp3InfoHelper
  TEST_TITLE        = "No Backrub"
  TEST_ARTIST       = "Bikini Kill"
  TEST_ALBUM        = "Reject All American"
  TEST_YEAR         = "1996"
  TEST_COMMENT      = "Feminism ruelz!"
  TEST_TRACK_NUMBER = 7
  TEST_GENRE_ID     = 43
  # ID3v1 genre ID 43 -> Punk
  TEST_GENRE_NAME   = "Punk"
  
  # not in the ID3v1 list of genres or the WinAmp extension list
  INVALID_GENRE_ID  = 253
  
  # Use a nice, big prime size for binary strings to push string writing and
  # reading routines harder
  #
  # http://primes.utm.edu/curios/page.php/78787.html
  TEST_PRIME        = 78787
  
  def get_valid_mp3
        # Command to create a dummy MP3
        # dd if=/dev/zero bs=1024 count=15 | lame --preset cbr 128 -r -s 44.1 --bitwidth 16 - - | ruby -rbase64 -e 'print Base64.encode64($stdin.read)'
    Base64.decode64 <<EOF
//uQZAAAAAAAaQYAAAAAAA0gwAAAAAABpBwAAAAAADSDgAAATEFNRTMuOTNV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVTEFNRTMuOTNVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVV//uSZL6P8AAAaQAAAAAAAA0gAAAAAAABpAAAAAAAADSA
AAAAVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjkzVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVf/7kmT/j/AAAGkAAAAAAAANIAAA
AAAAAaQAAAAAAAA0gAAAAFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVM
QU1FMy45M1VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+5Jk/4/w
AABpAAAAAAAADSAAAAAAAAGkAAAAAAAANIAAAABVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVTEFNRTMuOTNVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVV//uSZP+P8AAAaQAAAAAAAA0gAAAAAAABpAAAAAAAADSAAAAAVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVQ==
EOF
  end
  
  def create_sample_mp3_file(filename)
    File.open(filename, "w") { |f| f.write(get_valid_mp3) }
  end
  
  def sample_id3v1_0_attrs
    [ TEST_TITLE,
      TEST_ARTIST,
      TEST_ALBUM,
      TEST_YEAR,
      TEST_COMMENT,
      TEST_GENRE_ID ]
  end
  
  def sample_id3v1_1_attrs
    [ TEST_TITLE,
      TEST_ARTIST,
      TEST_ALBUM,
      TEST_YEAR,
      TEST_COMMENT,
      TEST_TRACK_NUMBER,
      TEST_GENRE_ID ]
  end
  
  def sample_id3v1_tag
    { "title"    => TEST_TITLE,
      "artist"   => TEST_ARTIST,
      "album"    => TEST_ALBUM,
      "year"     => TEST_YEAR,
      "comments" => TEST_COMMENT,
      "genre"    => TEST_GENRE_ID,
      "genre_s"  => TEST_GENRE_NAME,
      "tracknum" => TEST_TRACK_NUMBER }
  end
  
  def sample_id3v2_tag
    { "COMM" => ID3V24::Frame.create_frame("COMM", TEST_COMMENT),
      "TCON" => ID3V24::Frame.create_frame("TCON", TEST_GENRE_NAME),
      "TIT2" => ID3V24::Frame.create_frame("TIT2", TEST_TITLE),
      "TPE1" => ID3V24::Frame.create_frame("TPE1", TEST_ARTIST),
      "TALB" => ID3V24::Frame.create_frame("TALB", TEST_ALBUM),
      "TYER" => ID3V24::Frame.create_frame("TYER", TEST_YEAR),
      "TRCK" => ID3V24::Frame.create_frame("TRCK", "#{TEST_TRACK_NUMBER}/12") }
  end
  
  def random_string
    out = ""
    TEST_PRIME.times { out << rand(256).chr }
    out
  end
  
  def create_valid_id3_1_0_file(filename)
    File.open(filename, "w") do |f|
      f.write(get_valid_mp3)
      # brutally low-level means of writing an ID3 tag on its own
      f.write("TAG#{sample_id3v1_0_attrs.pack('A30A30A30A4A30C')}")
    end
  end
  
  def create_valid_id3_1_1_file(filename)
    File.open(filename, "w") do |f|
      f.write(get_valid_mp3)
      # brutally low-level means of writing an ID3v1.1 tag on its own
      f.write("TAG#{sample_id3v1_1_attrs.pack('A30A30A30A4a29CC')}")
    end
  end
  
  def update_id3_2_tag(filename, tag)
    Mp3Info.open(filename) do |mp3|
      mp3.tag2.update(tag)
    end
    
    Mp3Info.open(filename) { |m| m.tag2 }
  end
  
  def test_against_id3v2_prog(written_tag)
    return if PLATFORM =~ /win32/
    return if `which id3v2`.empty?
    
    start = false
    id3v2_output = {}
    `id3v2 -l #{@mp3_filename}`.each do |line|
      if line =~ /^id3v2 tag info/
        start = true
        next
      end
      next unless start
      k, v = /^(.{4}) \(.+\): (.+)$/.match(line)[1,2]
      
      #COMM (Comments): ()[spa]: fmg
      v.sub!(/\(\)\[.{3}\]: (.+)/, '\1') if k == "COMM"
      
      id3v2_output[k] = v
    end
    
    id3v2_output
  end
  
  def prettify_tag(tag)
    prettified_tag = {}
    
    tag.each do |key,value|
      prettified_tag[key] = value.to_s_pretty
    end
    
    prettified_tag
  end
end