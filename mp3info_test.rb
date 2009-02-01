#!/usr/bin/ruby -w

$:.unshift("lib/")

require "test/unit"
require "base64"
require "mp3info"
require "fileutils"

class Mp3InfoTest < Test::Unit::TestCase

  def test_reading_id3v2_2_tags
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'sample-metadata/Keith Fullerton Whitman/Multiples/Stereo Music For Hi-Hat.mp3'))
    tag2 = mp3.tag2
    
    assert_equal 'Keith Fullerton Whitman', tag2.TP1.value
    assert_equal 'Keith Fullerton Whitman', tag2.TCM.value
    assert_equal 'Multiples', tag2.TAL.value
    assert_equal '(26)', tag2.TCO.value
    assert_equal '2005', tag2.TYE.value
    assert_equal '1/8', tag2.TRK.value
  end
  
  def test_reading_id3v2_3_img_tags
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'sample-metadata/RAC/Double Jointed/03 - RAC - Nine.mp3'))
    tag2 = mp3.tag2

    assert_equal 7302, mp3.tag2_len
    assert_equal 5013, tag2.APIC.raw_size
    assert_equal 5013, tag2.APIC.value.size
  end
  
  def test_reading_invalid_id3v2_4_lengths
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'sample-metadata/Jurgen Paape/Speicher 47/01 Fruity Loops 1.mp3'))
    tag2 = mp3.tag2

    assert_equal 35_092, mp3.tag2_len
    assert_equal 34_685, tag2.APIC.raw_size
    assert_equal 34_685, tag2.APIC.value.size
    assert_equal 'eng', tag2.COMM.first.language
    assert_equal '<<in Love With The Music>>', tag2.COMM.first.value
    assert_equal 'http://www.kompakt-net.com', tag2.WXXX.value
    assert_equal 'Jürgen Paape', tag2.TPE1.value
    assert_equal 'Kompakt Extra 47', tag2.TIT1.value
    assert_equal 'Fruity Loops 1', tag2.TIT2.value
    assert_equal '2007', tag2.TDRC.value
    assert_equal 'German', tag2.TLAN.value
    assert_equal 'LAME 3.96', tag2.TENC.value
    assert_equal 'Techno', tag2.TCON.value
  end
  
  def test_reading_tag_with_repeated_frames
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),"sample-metadata/Master Fool/Skilligans Island/Master Fool - Skilligan's Island - 14 - I Still Live With My Moms.mp3"))
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
    assert_nothing_raised { mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'./sample-metadata/230-unicode.tag')) }
  end
  
  def test_read_tag_from_file_with_mpeg_header
    assert_nothing_raised { mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'./sample-metadata/zovietfrance/Popular Soviet Songs And Youth Music disc 3/zovietfrance - Popular Soviet Songs And Youth Music - 08 - Shewel.mp3')) }
  end
end
