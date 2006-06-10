#!/usr/bin/ruby -w

$:.unshift("lib/")

require "test/unit"
require "base64"
require "mp3info"
require "fileutils"

class Mp3InfoTest < Test::Unit::TestCase

  TEMP_FILE = "test_mp3info.mp3"
  BASIC_TAG2 = {
    "COMM" => ID3V24::Frame.create_frame("COMM", "comments"),
    "TCON" => ID3V24::Frame.create_frame("TCON", "genre_s"), 
    "TIT2" => ID3V24::Frame.create_frame("TIT2", "title"),
    "TPE1" => ID3V24::Frame.create_frame("TPE1", "artist"),
    "TALB" => ID3V24::Frame.create_frame("TALB", "album"),
    "TYER" => ID3V24::Frame.create_frame("TYER", "year"),
    "TRCK" => ID3V24::Frame.create_frame("TRCK", "tracknum")
  }
  
  # aliasing to allow testing with old versions of Test::Unit
  alias set_up setup 
  alias tear_down teardown

  def setup
    # Command to create a dummy MP3
    # dd if=/dev/zero bs=1024 count=15 | lame --preset cbr 128 -r -s 44.1 --bitwidth 16 - - | ruby -rbase64 -e 'print Base64.encode64($stdin.read)'
    @valid_mp3 = Base64.decode64 <<EOF
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
    @tag = {
      "title" => "title",
      "artist" => "artist",
      "album" => "album",
      "year" => 1921,
      "comments" => "comments",
      "genre" => 0,
      "genre_s" => "Blues",
      "tracknum" => 36
    }
    File.open(TEMP_FILE, "w") { |f| f.write(@valid_mp3) }
  end

  def teardown
    FileUtils.rm_f(TEMP_FILE)
  end


  def test_to_s
    Mp3Info.open(TEMP_FILE) { |info| assert(info.to_s.is_a?(String)) }
  end

  def test_not_an_mp3
    File.open(TEMP_FILE, "w") do |f|
      str = "0"*32*1024
      f.write(str)
    end
    assert_raises(Mp3InfoError) {
      mp3 = Mp3Info.new(TEMP_FILE)
    }
  end

  def test_is_an_mp3
    assert_nothing_raised {
      Mp3Info.new(TEMP_FILE).close
    }
  end
  
  def test_detected_info
    Mp3Info.open(TEMP_FILE) do |info|
      assert_equal(info.mpeg_version, 1)
      assert_equal(info.layer, 3)
      assert_equal(info.vbr, false)
      assert_equal(info.bitrate, 128)
      assert_equal(info.channel_mode, "JStereo")
      assert_equal(info.samplerate, 44100)
      assert_equal(info.error_protection, false)
      assert_equal(info.length, 0.1305625)
    end
  end

  def test_removetag1
    Mp3Info.open(TEMP_FILE) { |info| info.tag1 = @tag }
    assert(Mp3Info.hastag1?(TEMP_FILE))
    Mp3Info.removetag1(TEMP_FILE)
    assert(! Mp3Info.hastag1?(TEMP_FILE))
  end

  def test_removetag1_inside_block
    Mp3Info.open(TEMP_FILE) { |info| info.tag1 = @tag }
    assert(Mp3Info.hastag1?(TEMP_FILE))
    Mp3Info.open(TEMP_FILE) { |mp3info| Mp3Info.removetag1(TEMP_FILE) }
    assert(! Mp3Info.hastag1?(TEMP_FILE))
  end

  def test_writetag1
    Mp3Info.open(TEMP_FILE) { |info| info.tag1 = @tag }
    Mp3Info.open(TEMP_FILE) { |info| assert(info.tag1 == @tag) }
  end

  def test_valid_tag1_1
    tag = [ "title", "artist", "album", "1921", "comments", 36, 0].pack('A30A30A30A4a29CC')
    valid_tag = {
      "title" => "title",
      "artist" => "artist",
      "album" => "album",
      "year" => 1921,
      "comments" => "comments",
      "genre" => "Blues",
      #"version" => "1",
      "tracknum" => 36
    }
    id3_test(tag, valid_tag)
  end
  
  def test_valid_tag1_0
    tag = [ "title", "artist", "album", "1921", "comments", 0].pack('A30A30A30A4A30C')
    valid_tag = {
      "title" => "title",
      "artist" => "artist",
      "album" => "album",
      "year" => 1921,
      "comments" => "comments",
      "genre" => "Blues",
      #"version" => "0"
    }
    id3_test(tag, valid_tag)
  end

  def id3_test(tag_str, valid_tag)
    tag = "TAG" + tag_str
    File.open(TEMP_FILE, "w") do |f|
      f.write(@valid_mp3)
      f.write(tag)
    end
    assert(Mp3Info.hastag1?(TEMP_FILE))
    #info = Mp3Info.new(TEMP_FILE)
    #FIXME validate this test
    #assert_equal(info.tag1, valid_tag)
  end

  def test_removetag2
    w = write_temp_file({"TIT2" => ID3V24::Frame.create_frame('TIT2', "sdfqdsf")})

    assert( Mp3Info.hastag2?(TEMP_FILE) )
    Mp3Info.removetag2(TEMP_FILE)
    assert( ! Mp3Info.hastag2?(TEMP_FILE) )
  end

  def test_universal_tag
    2.times do 
      tag = {"title" => "title"}
      Mp3Info.open(TEMP_FILE) do |mp3|
        tag.each { |k,v| mp3.tag[k] = v }
      end
      w = Mp3Info.open(TEMP_FILE) { |m| m.tag }
      assert_equal(tag, w)
    end
  end

  def test_id3v2_universal_tag
    tag = {}
    %w{comments title artist album}.each { |k| tag[k] = k }
    tag["tracknum"] = 34
    Mp3Info.open(TEMP_FILE) do |mp3|
      tag.each { |k,v| mp3.tag[k] = v }
    end
    w = Mp3Info.open(TEMP_FILE) { |m| m.tag }
    w.delete("genre")
    w.delete("genre_s")
    assert_equal(tag, w)
    # id3v2_prog_test(tag, w)
  end

  def test_id3v2_version
    written_tag = write_temp_file(BASIC_TAG2)
    assert_equal( "2.4.0", written_tag.version )
  end

  def test_id3v2_methods
    tag = {
      "TIT2" => ID3V24::Frame.create_frame("TIT2", "tit2"),
      "TPE1" => ID3V24::Frame.create_frame("TPE1", "tpe1")
      }
    Mp3Info.open(TEMP_FILE) do |mp3|
      tag.each do |k, v|
        mp3.tag2.send("#{k}=".to_sym, v)
      end
      assert_equal(tag, mp3.tag2)
    end
  end

  def test_id3v2_frame_creation
    # getting the defaults right is most important
    assert_equal ID3V24::Frame,     ID3V24::Frame.create_frame('XXXX', 0).class
    assert_equal ID3V24::TextFrame, ID3V24::Frame.create_frame('TPOS', '1/14').class
    assert_equal ID3V24::LinkFrame, ID3V24::Frame.create_frame('WOAR', 'http://www.dresdendolls.com/').class
    
    # simple example of a customized frame
    assert_equal ID3V24::TCONFrame,      ID3V24::Frame.create_frame('TCON', 'Experimetal').class
  end
  
  def test_id3v2_basic
    w = write_temp_file(BASIC_TAG2)
    assert_equal(BASIC_TAG2, w)
    id3v2_prog_test(BASIC_TAG2, w)
  end

  def test_id3v2_complex
    tag = {}
    ["PRIV", "APIC"].each do |k|
      tag[k] = ID3V24::Frame.create_frame(k, random_string(50))
    end

    Mp3Info.open(TEMP_FILE) do |mp3|
      mp3.tag2.update(tag)
      before_save_tag = mp3.tag2
    end
    after_save_tag = Mp3Info.open(TEMP_FILE) { |m| m.tag2 }

    assert_equal(tag, write_temp_file(tag))
  end
  
  def test_casual_use
    Mp3Info.open(TEMP_FILE) do |mp3|
      mp3.tag2.WCOM = "http://www.riaa.org/"
      mp3.tag2.TXXX=("A sample comment")
    end
    
    mp3 = Mp3Info.new(TEMP_FILE)
    tag2 = mp3.tag2
    
    assert_equal "http://www.riaa.org/", tag2.WCOM.value
    assert_equal "A sample comment", tag2.TXXX.value
  end

  def test_id3v2_bigtag
    tag = {"APIC" => ID3V24::Frame.create_frame("APIC", random_string(1024)) }
    assert_equal(tag, write_temp_file(tag))
  end
  
  def test_nonexistent_frame_type
    crud = random_string(64)
    tag = { "XNXT" => ID3V24::Frame.create_frame("XNXT", crud) }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::Frame, saved_tag.XNXT.class
    assert_equal crud, saved_tag.XNXT.value
    assert_equal crud.inspect, saved_tag.XNXT.to_s_pretty
    assert_equal "No description available for frame type 'XNXT'.",
                 saved_tag.XNXT.frame_info
  end
  
  def test_generic_text_frame_with_frame_info
    tag = { "TPE3" => ID3V24::Frame.create_frame("TPE3", "Leopold Stokowski") }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::TextFrame, saved_tag.TPE3.class
    assert_equal "Leopold Stokowski", saved_tag.TPE3.value
    assert_equal "Leopold Stokowski", saved_tag.TPE3.to_s_pretty
    assert_equal "The 'Conductor' frame is used for the name of the conductor.",
                 saved_tag.TPE3.frame_info
  end
  
  def test_generic_link_frame_with_frame_info
    tag = { "WOAF" => ID3V24::Frame.create_frame("WOAF", "http://example.com/audio.html") }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::LinkFrame, saved_tag.WOAF.class
    assert_equal "http://example.com/audio.html", saved_tag.WOAF.value
    assert_equal "URL: http://example.com/audio.html", saved_tag.WOAF.to_s_pretty
    assert_equal "The 'Official audio file webpage' frame is a URL pointing at a file specific webpage.",
                 saved_tag.WOAF.frame_info
  end
  
  def test_frame_encoding_iso_8859_1
    tit2 = ID3V24::Frame.create_frame("TIT2", "Junior Citizen (lé Freak!)")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:iso]
    tag = { "TIT2" => tit2 }
    saved_tag = write_temp_file(tag)
    
    assert_equal 0, saved_tag.TIT2.encoding
    assert_equal "Junior Citizen (lé Freak!)", saved_tag.TIT2.value
  end
  
  def test_frame_encoding_utf_16_with_byte_order_mark 
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:utf16]
    tag = { "TIT2" => tit2 }
    saved_tag = write_temp_file(tag)
    
    assert_equal 1, saved_tag.TIT2.encoding
    assert_equal "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈", saved_tag.TIT2.value
  end
  
  def test_frame_encoding_utf_16_big_endian 
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:utf16be]
    tag = { "TIT2" => tit2 }
    saved_tag = write_temp_file(tag)
    
    assert_equal 2, saved_tag.TIT2.encoding
    assert_equal "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈", saved_tag.TIT2.value
  end
  
  def test_frame_encoding_utf_8 
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:utf8]
    tag = { "TIT2" => tit2 }
    saved_tag = write_temp_file(tag)
    
    assert_equal 3, saved_tag.TIT2.encoding
    assert_equal "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈", saved_tag.TIT2.value
  end
  
  def test_frame_encoding_iso_8859_1_encoding_error 
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:iso]
    tag = { "TIT2" => tit2 }
    assert_raises(Iconv::IllegalSequence) { write_temp_file(tag) }
  end
  
  def test_tag_default_apic
    random_data = random_string(128)
    tag = { "APIC" => ID3V24::Frame.create_frame("APIC", random_data) }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::APICFrame, saved_tag.APIC.class
    assert_equal 3, saved_tag.APIC.encoding
    assert_equal 'image/jpeg', saved_tag.APIC.mime_type
    assert_equal "\x00", saved_tag.APIC.picture_type
    assert_equal random_data, saved_tag.APIC.value
    assert_equal "Attached Picture (cover image) of image type image/jpeg and class Other",
                 saved_tag.APIC.to_s_pretty
  end
  
  def test_tag_default_comm
    tag = { "COMM" => ID3V24::Frame.create_frame("COMM", "This is a sample comment.") }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::COMMFrame, saved_tag.COMM.class
    assert_equal 3, saved_tag.COMM.encoding
    assert_equal 'Mp3Info Comment', saved_tag.COMM.description
    assert_equal "This is a sample comment.", saved_tag.COMM.value
    assert_equal "(Mp3Info Comment)[ENG]: This is a sample comment.",
                 saved_tag.COMM.to_s_pretty
  end
  
  def test_tag_default_priv
    random_data = random_string(128)
    tag = { "PRIV" => ID3V24::Frame.create_frame("PRIV", random_data) }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::PRIVFrame, saved_tag.PRIV.class
    assert_equal 'mailto:ogd@aoaioxxysz.net', saved_tag.PRIV.owner
    assert_equal random_data, saved_tag.PRIV.value
    assert_equal "PRIVATE DATA (from mailto:ogd@aoaioxxysz.net) [#{random_data.inspect}]",
                 saved_tag.PRIV.to_s_pretty
  end
  
  def test_tag_default_tcmp_true
    tag = { "TCMP" => ID3V24::Frame.create_frame("TCMP", true) }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::TCMPFrame, saved_tag.TCMP.class
    assert_equal true, saved_tag.TCMP.value
    assert_equal "This track is part of a compilation.", saved_tag.TCMP.to_s_pretty
  end
  
  def test_tag_default_tcmp_false
    tag = { "TCMP" => ID3V24::Frame.create_frame("TCMP", false) }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::TCMPFrame, saved_tag.TCMP.class
    assert_equal false, saved_tag.TCMP.value
    assert_equal "This track is not part of a compilation.", saved_tag.TCMP.to_s_pretty
  end
  
  def test_tag_default_tcon
    tag = { "TCON" => ID3V24::Frame.create_frame("TCON", 'Jungle') }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::TCONFrame, saved_tag.TCON.class
    assert_equal "Jungle", saved_tag.TCON.value
    assert_equal 63, saved_tag.TCON.genre_code
    assert_equal "Jungle (63)", saved_tag.TCON.to_s_pretty
  end
  
  def test_tag_default_txxx
    tag = { "TXXX" => ID3V24::Frame.create_frame("TXXX", "Here is some random user-defined text.") }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::TXXXFrame, saved_tag.TXXX.class
    assert_equal 3, saved_tag.TXXX.encoding
    assert_equal 'Mp3Info Comment', saved_tag.TXXX.description
    assert_equal "Here is some random user-defined text.", saved_tag.TXXX.value
    assert_equal "(Mp3Info Comment) : Here is some random user-defined text.",
                 saved_tag.TXXX.to_s_pretty
  end
  
  def test_tag_default_wxxx
    tag = { "WXXX" => ID3V24::Frame.create_frame("WXXX", "http://www.yourmom.gov") }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::WXXXFrame, saved_tag.WXXX.class
    assert_equal 3, saved_tag.WXXX.encoding
    assert_equal 'Mp3Info User Link Frame', saved_tag.WXXX.description
    assert_equal "http://www.yourmom.gov", saved_tag.WXXX.value
    assert_equal "(Mp3Info User Link Frame) : http://www.yourmom.gov",
                 saved_tag.WXXX.to_s_pretty
  end
  
  def test_tag_default_ufid
    tag = { "UFID" => ID3V24::Frame.create_frame("UFID", "2451-4235-af32a3-1312") }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::UFIDFrame, saved_tag.UFID.class
    assert_equal "http://www.id3.org/dummy/ufid.html", saved_tag.UFID.namespace
    assert_equal "2451-4235-af32a3-1312", saved_tag.UFID.value
    assert_equal 'http://www.id3.org/dummy/ufid.html: "2451-4235-af32a3-1312"', saved_tag.UFID.to_s_pretty
  end
  
  def test_tag_default_xdor
    xdor = ID3V24::Frame.create_frame("XDOR", Time.gm(1993, 3, 8))
    assert_equal "\0031993-03-08", xdor.to_s
    tag = { "XDOR" => xdor }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::XDORFrame, saved_tag.XDOR.class
    assert_equal Time.gm(1993, 3, 8), saved_tag.XDOR.value
    assert_equal "Release date: Mon Mar 08 00:00:00 UTC 1993", saved_tag.XDOR.to_s_pretty
  end
  
  def test_tag_default_xsop
    tag = { "XSOP" => ID3V24::Frame.create_frame("XSOP", "Clash, The") }
    saved_tag = write_temp_file(tag)
    
    assert_equal ID3V24::XSOPFrame, saved_tag.XSOP.class
    assert_equal "Clash, The", saved_tag.XSOP.value
    assert_equal "Clash, The", saved_tag.XSOP.to_s_pretty
  end
  
  def test_tag_comm_with_unicode
    comm = ID3V24::Frame.create_frame("COMM", "Здравствуйте dïáçrìtícs!")
    comm.language = 'rus'
    tag = { "COMM" => comm }
    saved_tag = write_temp_file(tag)
    
    assert_equal 'rus', saved_tag.COMM.language
    assert_equal "Здравствуйте dïáçrìtícs!", saved_tag.COMM.value
    assert_equal "(Mp3Info Comment)[rus]: Здравствуйте dïáçrìtícs!",
                 saved_tag.COMM.to_s_pretty
  end
  
  def test_tag_tcon_with_no_genre_code
    tcon = ID3V24::Frame.create_frame("TCON", 'Experimental')
    tcon.encoding = 0
    tag = { "TCON" => tcon }
    saved_tag = write_temp_file(tag)
    
    assert_equal "Experimental", saved_tag.TCON.value
    assert_equal 255, saved_tag.TCON.genre_code
    assert_equal "Experimental (255)", saved_tag.TCON.to_s_pretty
  end
  
  def test_reading_id3v2_2_tags
    mp3 = Mp3Info.new('sample-metadata/Keith Fullerton Whitman/Multiples/Stereo Music For Hi-Hat.mp3')
    tag2 = mp3.tag2
    
    assert_equal 'Keith Fullerton Whitman', tag2.TP1.value
    assert_equal 'Keith Fullerton Whitman', tag2.TCM.value
    assert_equal 'Multiples', tag2.TAL.value
    assert_equal '(26)', tag2.TCO.value
    assert_equal '2005', tag2.TYE.value
    assert_equal '1/8', tag2.TRK.value
  end
  
  def test_reading_tag_with_repeated_frames
    mp3 = Mp3Info.new("sample-metadata/Master Fool/Skilligans Island/Master Fool - Skilligan's Island - 14 - I Still Live With My Moms.mp3")
    tag2 = mp3.tag2
    
    # COMM (Comments): ()[XXX]: RIPT with GRIP
    # COMM (Comments): ()[]: Created by Grip
    # COMM (Comments): (ID3v1 Comment)[XXX]: RIPT with GRIP
    # TALB (Album/Movie/Show title): Skilligan's Island
    # TALB (Album/Movie/Show title): Skilligan's Island
    # TCON (Content type): Indie Rap (255)
    # TIT2 (Title/songname/content description): I Still Live With My Moms
    # TIT2 (Title/songname/content description): I Still Live With My Moms
    # TPE1 (Lead performer(s)/Soloist(s)): Master Fool
    # TPE1 (Lead performer(s)/Soloist(s)): Master Fool
    # TRCK (Track number/Position in set): 14
    # TRCK (Track number/Position in set): 14
    # TYER (Year): 2002
    # TYER (Year): 2002
    
    assert_equal 3, tag2.COMM.size
    assert_equal 2, tag2.TALB.size
    assert_equal 2, tag2.TIT2.size
    assert_equal 2, tag2.TPE1.size
    assert_equal 2, tag2.TRCK.size
    assert_equal 2, tag2.TYER.size
    
    assert tag2.COMM.detect { |frame|
      'XXX' == frame.language && 
      '' == frame.description &&
      'RIPT with GRIP' == frame.value
    }
    
    assert tag2.COMM.detect { |frame|
      "\000\000\000" == frame.language && 
      '' == frame.description &&
      'Created by Grip' == frame.value
    }
    
    assert tag2.COMM.detect { |frame|
      'XXX' == frame.language && 
      'ID3v1 Comment' == frame.description &&
      'RIPT with GRIP' == frame.value
    }
  end
  
  def test_read_tag_from_truncated_file
    assert_nothing_raised { mp3 = Mp3Info.new('./sample-metadata/230-unicode.tag') }
  end
  
  def test_read_tag_from_file_with_mpeg_header
    assert_nothing_raised { mp3 = Mp3Info.new('./sample-metadata/zovietfrance/Popular Soviet Songs And Youth Music disc 3/zovietfrance - Popular Soviet Songs And Youth Music - 08 - Shewel.mp3') }
  end
  
  private # helper methods
  
  # test the tag with the "id3v2" program -- you'll need a version of id3lib
  # that's been patched to work with ID3v2 2.4.0 tags, which probably means
  # a version of id3lib above 3.8.3
  def id3v2_prog_test(tag, written_tag)
    return if PLATFORM =~ /win32/
    return if `which id3v2`.empty?
    start = false
    id3v2_output = {}
    `id3v2 -l #{TEMP_FILE}`.each do |line|
      if line =~ /^id3v2 tag info/
        start = true 
        next    
      end
      next unless start
      k, v = /^(.{4}) \(.+\): (.+)$/.match(line)[1,2]
      case k
        #COMM (Comments): ()[spa]: fmg
        when "COMM"
          v.sub!(/\(\)\[.{3}\]: (.+)/, '\1')
      end
      id3v2_output[k] = v
    end
    
    prettified_tag = {}
    written_tag.each do |key,value|
      prettified_tag[key] = value.to_s_pretty
    end

    assert_equal( id3v2_output, prettified_tag, "id3v2 program output doesn't match")
  end

  def write_temp_file(tag)
    Mp3Info.open(TEMP_FILE) do |mp3|
      mp3.tag2.update(tag)
    end
    return Mp3Info.open(TEMP_FILE) { |m| m.tag2 }
    #system("cp -v #{TEMP_FILE} #{TEMP_FILE}.test")
  end

  def random_string(size)
    out = ""
    size.times { out << rand(256).chr }
    out
  end

=begin

  def test_encoder
    write_to_temp
    info = Mp3Info.new(TEMP_FILE)
    assert(info.encoder == "Lame 3.93")
  end

  def test_vbr
    mp3_vbr = Base64.decode64 <<EOF

EOF
    File.open(TEMP_FILE, "w") { |f| f.write(mp3_vbr) }
    info = Mp3Info.new(TEMP_FILE)
    assert_equal(info.vbr, true)
    assert_equal(info.bitrate, 128)
  end
=end
end
