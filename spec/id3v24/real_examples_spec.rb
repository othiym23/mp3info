# encoding: utf-8
$:.unshift("lib/")

require 'digest/sha1'
require 'mp3info'

describe ID3V24::Frame, "when reading examples of real MP3 files" do
  it "should read ID3v2.2 tags correctly" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Keith Fullerton Whitman/Multiples/Stereo Music For Hi-Hat.mp3'))
    id3v2_tag = mp3.id3v2_tag
    
    id3v2_tag['TP1'].value.should == 'Keith Fullerton Whitman'
    id3v2_tag['TCM'].value.should == 'Keith Fullerton Whitman'
    id3v2_tag['TAL'].value.should == 'Multiples'
    id3v2_tag['TCO'].value.should == 'Ambient'
    id3v2_tag['TCO'].genre_code.should == 26
    id3v2_tag['TCO'].to_s_pretty.should == 'Ambient (26)'
    id3v2_tag['TYE'].value.should == '2005'
    id3v2_tag['TRK'].value.should == '1/8'
  end
  
  it "should read image frames from ID3v2.3 tags without mangling them" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/RAC/Double Jointed/03 - RAC - Nine.mp3'))
    id3v2_tag = mp3.id3v2_tag
    
    mp3.id3v2_tag.tag_length.should == 7302
    id3v2_tag['APIC'].raw_size.should == 5026
    Digest::SHA1.hexdigest(id3v2_tag['APIC'].value).should == '6902c6f4f81838208dd26f88274bf7444f7798a7'
    id3v2_tag['APIC'].value.size.should == 5013
  end
  
  it "should correctly read frame lengths from ID3v2.4 tags even if the lengths aren't encoded syncsafe" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Jurgen Paape/Speicher 47/01 Fruity Loops 1.mp3'))
    id3v2_tag = mp3.id3v2_tag
    
    # we should be able to retrieve the information, but we should rewrite this tag
    id3v2_tag.valid_frame_sizes?.should be_false
    # and this should render the whole tag invalid
    id3v2_tag.valid?.should be_false
    mp3.id3v2_tag.tag_length.should == 35_092
    id3v2_tag['APIC'].raw_size.should == 34_698
    id3v2_tag['APIC'].value.size.should == 34_685
    id3v2_tag['COMM'].first.language.should == 'eng'
    id3v2_tag['COMM'].first.value.should == '<<in Love With The Music>>'
    id3v2_tag['WXXX'].value.should == 'http://www.kompakt-net.com'
    id3v2_tag['TPE1'].value.should == 'Jürgen Paape'
    id3v2_tag['TIT1'].value.should == 'Kompakt Extra 47'
    id3v2_tag['TIT2'].value.should == 'Fruity Loops 1'
    id3v2_tag['TDRC'].value.should == '2007'
    id3v2_tag['TLAN'].value.should == 'German'
    id3v2_tag['TENC'].value.should == 'LAME 3.96'
    id3v2_tag['TCON'].value.should == 'Techno'
  end
  
  it "should not crash and correctly display a summary for a file containing no MPEG audio data" do
    mp3 = nil
    lambda { mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/3aeb9bc1396b9b840c677e161e731908a4a66464.mp3')) }.should_not raise_error(NoMethodError)
    mp3.duration_string.should == "-"
    mp3.to_s.should == "NO AUDIO FOUND"
  end
  
  it "should not crash with a dual channel stereo stream with non-synchsafe ID3v2.4 frame sizes" do
    mp3 = nil
    lambda { mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/mp3info-qa/00f9c130c607ea84c6cd1792a6cf49fdd1e3f4a9.mp3')) }.should_not raise_error(NoMethodError)
    mp3.to_s.should == "Time: 0:00        MPEG1, layer III [ 160kbps @ 44.1kHz - Dual channel stereo +E ]"
    mp3.has_id3v2_tag?.should be_true
    id3v2_tag = mp3.id3v2_tag
    id3v2_tag.valid_frame_sizes?.should be_false
    id3v2_tag.valid?.should be_false
    id3v2_tag['TALB'].value.should == 'Volume 1: Operation Start-Up'
    id3v2_tag['TPE1'].value.should == 'Rod Lee'
    id3v2_tag['TIT2'].value.should == 'What They Do?'
    id3v2_tag['TCON'].value.should == 'Baltimore Club'
    id3v2_tag['TYER'].value.should == '2005'
    id3v2_tag['TRCK'].value.should == '24/32'
    id3v2_tag['TPOS'].value.should == '1/1'
    id3v2_tag['APIC'].raw_size.should == 465_953
  end
  
  it "should correctly find all the repeated frames, no matter how many are in a tag" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),"../../sample-metadata/Master Fool/Skilligans Island/Master Fool - Skilligan's Island - 14 - I Still Live With My Moms.mp3"))
    id3v2_tag = mp3.id3v2_tag
    
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
    
    id3v2_tag['COMM'].size.should == 3
    id3v2_tag['COMM'].detect { |frame|
      'XXX' == frame.language && 
      '' == frame.description &&
      'RIPT with GRIP' == frame.value
    }.should be_true
    
    id3v2_tag['COMM'].detect { |frame|
      "\000\000\000" == frame.language && 
      '' == frame.description &&
      'Created by Grip' == frame.value
    }.should be_true
    
    id3v2_tag['COMM'].detect { |frame|
      'XXX' == frame.language && 
      'ID3v1 Comment' == frame.description &&
      'RIPT with GRIP' == frame.value
    }.should be_true
    
    id3v2_tag['TALB'].size.should == 2
    id3v2_tag['TALB'].detect { |frame|
      'Skilligan\'s Island' == frame.value
    }.should be_true
    
    id3v2_tag['TIT2'].size.should == 2
    id3v2_tag['TIT2'].detect { |frame|
      'I Still Live With My Moms' == frame.value
    }.should be_true
    
    id3v2_tag['TPE1'].size.should == 2
    id3v2_tag['TPE1'].detect { |frame|
      'Master Fool' == frame.value
    }.should be_true
    
    id3v2_tag['TRCK'].size.should == 2
    id3v2_tag['TRCK'].detect { |frame|
      '14' == frame.value
    }.should be_true
    
    id3v2_tag['TYER'].size.should == 2
    id3v2_tag['TYER'].detect { |frame|
      '2002' == frame.value
    }.should be_true
  end
end
