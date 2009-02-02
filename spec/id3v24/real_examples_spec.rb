$:.unshift("lib/")

require 'digest/sha1'
require 'mp3info'

describe ID3V24::Frame, "when reading examples of real MP3 files" do
  it "should read ID3v2.2 tags correctly" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Keith Fullerton Whitman/Multiples/Stereo Music For Hi-Hat.mp3'))
    tag2 = mp3.tag2
    
    tag2.TP1.value.should == 'Keith Fullerton Whitman'
    tag2.TCM.value.should == 'Keith Fullerton Whitman'
    tag2.TAL.value.should == 'Multiples'
    tag2.TCO.value.should == 'Ambient'
    tag2.TCO.genre_code.should == 26
    tag2.TCO.to_s_pretty.should == 'Ambient (26)'
    tag2.TYE.value.should == '2005'
    tag2.TRK.value.should == '1/8'
  end
  
  it "should read image frames from ID3v2.3 tags without mangling them" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/RAC/Double Jointed/03 - RAC - Nine.mp3'))
    tag2 = mp3.tag2
    
    mp3.tag2_len.should == 7302
    tag2['APIC'].raw_size.should == 5026
    Digest::SHA1.hexdigest(tag2['APIC'].value).should == '6902c6f4f81838208dd26f88274bf7444f7798a7'
    tag2['APIC'].value.size.should == 5013
  end
  
  it "should correctly read frame lengths from ID3v2.4 tags even if the lengths aren't encoded syncsafe" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Jurgen Paape/Speicher 47/01 Fruity Loops 1.mp3'))
    tag2 = mp3.tag2
    
    mp3.tag2_len.should == 35_092
    tag2['APIC'].raw_size.should == 34_698
    tag2['APIC'].value.size.should == 34_685
    tag2['COMM'].first.language.should == 'eng'
    tag2['COMM'].first.value.should == '<<in Love With The Music>>'
    tag2['WXXX'].value.should == 'http://www.kompakt-net.com'
    tag2['TPE1'].value.should == 'Jürgen Paape'
    tag2['TIT1'].value.should == 'Kompakt Extra 47'
    tag2['TIT2'].value.should == 'Fruity Loops 1'
    tag2['TDRC'].value.should == '2007'
    tag2['TLAN'].value.should == 'German'
    tag2['TENC'].value.should == 'LAME 3.96'
    tag2['TCON'].value.should == 'Techno'
  end
  
  it "should correctly find all the repeated frames, no matter how many are in a tag" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),"../../sample-metadata/Master Fool/Skilligans Island/Master Fool - Skilligan's Island - 14 - I Still Live With My Moms.mp3"))
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
    
    tag2['COMM'].size.should == 3
    tag2['COMM'].detect { |frame|
      'XXX' == frame.language && 
      '' == frame.description &&
      'RIPT with GRIP' == frame.value
    }.should be_true
    
    tag2['COMM'].detect { |frame|
      "\000\000\000" == frame.language && 
      '' == frame.description &&
      'Created by Grip' == frame.value
    }.should be_true
    
    tag2['COMM'].detect { |frame|
      'XXX' == frame.language && 
      'ID3v1 Comment' == frame.description &&
      'RIPT with GRIP' == frame.value
    }.should be_true
    
    tag2['TALB'].size.should == 2
    tag2['TALB'].detect { |frame|
      'Skilligan\'s Island' == frame.value
    }.should be_true
    
    tag2['TIT2'].size.should == 2
    tag2['TIT2'].detect { |frame|
      'I Still Live With My Moms' == frame.value
    }.should be_true
    
    tag2['TPE1'].size.should == 2
    tag2['TPE1'].detect { |frame|
      'Master Fool' == frame.value
    }.should be_true
    
    tag2['TRCK'].size.should == 2
    tag2['TRCK'].detect { |frame|
      '14' == frame.value
    }.should be_true
    
    tag2['TYER'].size.should == 2
    tag2['TYER'].detect { |frame|
      '2002' == frame.value
    }.should be_true
  end
end
