require "digest/sha1"
require "mp3info"

describe ID3V24::Frame, "when reading examples of real MP3 files" do
  it "should read ID3v2.2 tags correctly" do
    mp3 = Mp3Info.new(File.join(__dir__, "../../sample-metadata/Keith Fullerton Whitman/Multiples/Stereo Music For Hi-Hat.mp3"))
    id3v2_tag = mp3.id3v2_tag

    expect(id3v2_tag["TP1"].value).to eq("Keith Fullerton Whitman")
    expect(id3v2_tag["TCM"].value).to eq("Keith Fullerton Whitman")
    expect(id3v2_tag["TAL"].value).to eq("Multiples")
    expect(id3v2_tag["TCO"].value).to eq("Ambient")
    expect(id3v2_tag["TCO"].genre_code).to eq(26)
    expect(id3v2_tag["TCO"].to_s_pretty).to eq("Ambient (26)")
    expect(id3v2_tag["TYE"].value).to eq("2005")
    expect(id3v2_tag["TRK"].value).to eq("1/8")
  end

  it "should read image frames from ID3v2.3 tags without mangling them" do
    mp3 = Mp3Info.new(File.join(__dir__, "../../sample-metadata/RAC/Double Jointed/03 - RAC - Nine.mp3"))
    id3v2_tag = mp3.id3v2_tag

    expect(mp3.id3v2_tag.tag_length).to eq(7302)
    expect(id3v2_tag["APIC"].raw_size).to eq(5026)
    expect(Digest::SHA1.hexdigest(id3v2_tag["APIC"].value)).to eq("6902c6f4f81838208dd26f88274bf7444f7798a7")
    expect(id3v2_tag["APIC"].value.size).to eq(5013)
  end

  it "should correctly read frame lengths from ID3v2.4 tags even if the lengths aren't encoded syncsafe" do
    mp3 = Mp3Info.new(File.join(__dir__, "../../sample-metadata/Jurgen Paape/Speicher 47/01 Fruity Loops 1.mp3"))
    id3v2_tag = mp3.id3v2_tag

    # we should be able to retrieve the information, but we should rewrite this tag
    expect(id3v2_tag.valid_frame_sizes?).to be false
    # and this should render the whole tag invalid
    expect(id3v2_tag.valid?).to be false
    expect(mp3.id3v2_tag.tag_length).to eq(35_092)
    expect(id3v2_tag["APIC"].raw_size).to eq(34_698)
    expect(id3v2_tag["APIC"].value.size).to eq(34_685)
    expect(id3v2_tag["COMM"].first.language).to eq("eng")
    expect(id3v2_tag["COMM"].first.value).to eq("<<in Love With The Music>>")
    expect(id3v2_tag["WXXX"].value).to eq("http://www.kompakt-net.com")
    expect(id3v2_tag["TPE1"].value).to eq("Jürgen Paape")
    expect(id3v2_tag["TIT1"].value).to eq("Kompakt Extra 47")
    expect(id3v2_tag["TIT2"].value).to eq("Fruity Loops 1")
    expect(id3v2_tag["TDRC"].value).to eq("2007")
    expect(id3v2_tag["TLAN"].value).to eq("German")
    expect(id3v2_tag["TENC"].value).to eq("LAME 3.96")
    expect(id3v2_tag["TCON"].value).to eq("Techno")
  end

  it "should not crash and correctly display a summary for a file containing no MPEG audio data" do
    mp3 = nil
    expect { mp3 = Mp3Info.new(File.join(__dir__, "../../sample-metadata/mp3info-qa/3aeb9bc1396b9b840c677e161e731908a4a66464.mp3")) }.not_to raise_error
    expect(mp3.duration_string).to eq("-")
    expect(mp3.to_s).to eq("NO AUDIO FOUND")
  end

  it "should not crash with a dual channel stereo stream with non-synchsafe ID3v2.4 frame sizes" do
    mp3 = nil
    expect { mp3 = Mp3Info.new(File.join(__dir__, "../../sample-metadata/mp3info-qa/00f9c130c607ea84c6cd1792a6cf49fdd1e3f4a9.mp3")) }.not_to raise_error
    expect(mp3.to_s).to eq("Time: 0:00        MPEG1, layer III [ 160kbps @ 44.1kHz - Dual channel stereo +E ]")
    expect(mp3.has_id3v2_tag?).to be true
    id3v2_tag = mp3.id3v2_tag
    expect(id3v2_tag.valid_frame_sizes?).to be false
    expect(id3v2_tag.valid?).to be false
    expect(id3v2_tag["TALB"].value).to eq("Volume 1: Operation Start-Up")
    expect(id3v2_tag["TPE1"].value).to eq("Rod Lee")
    expect(id3v2_tag["TIT2"].value).to eq("What They Do?")
    expect(id3v2_tag["TCON"].value).to eq("Baltimore Club")
    expect(id3v2_tag["TYER"].value).to eq("2005")
    expect(id3v2_tag["TRCK"].value).to eq("24/32")
    expect(id3v2_tag["TPOS"].value).to eq("1/1")
    expect(id3v2_tag["APIC"].raw_size).to eq(465_953)
  end

  it "should correctly find all the repeated frames, no matter how many are in a tag" do
    mp3 = Mp3Info.new(File.join(__dir__, "../../sample-metadata/Master Fool/Skilligans Island/Master Fool - Skilligan's Island - 14 - I Still Live With My Moms.mp3"))
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

    expect(id3v2_tag["COMM"].size).to eq(3)
    expect(id3v2_tag["COMM"].detect { |frame|
      frame.language == "XXX" &&
      frame.description == "" &&
      frame.value == "RIPT with GRIP"
    }).to be_truthy

    expect(id3v2_tag["COMM"].detect { |frame|
      frame.language == "\000\000\000" &&
      frame.description == "" &&
      frame.value == "Created by Grip"
    }).to be_truthy

    expect(id3v2_tag["COMM"].detect { |frame|
      frame.language == "XXX" &&
      frame.description == "ID3v1 Comment" &&
      frame.value == "RIPT with GRIP"
    }).to be_truthy

    expect(id3v2_tag.find_frames_by_description("ID3v1 Comment").size).to eq(1)
    expect(id3v2_tag.find_frames_by_description("ID3v1 Comment").first.value).to eq("RIPT with GRIP")

    expect(id3v2_tag["TALB"].size).to eq(2)
    expect(id3v2_tag["TALB"].detect { |frame|
      frame.value == "Skilligan's Island"
    }).to be_truthy

    expect(id3v2_tag["TIT2"].size).to eq(2)
    expect(id3v2_tag["TIT2"].detect { |frame|
      frame.value == "I Still Live With My Moms"
    }).to be_truthy

    expect(id3v2_tag["TPE1"].size).to eq(2)
    expect(id3v2_tag["TPE1"].detect { |frame|
      frame.value == "Master Fool"
    }).to be_truthy

    expect(id3v2_tag["TRCK"].size).to eq(2)
    expect(id3v2_tag["TRCK"].detect { |frame|
      frame.value == "14"
    }).to be_truthy

    expect(id3v2_tag["TYER"].size).to eq(2)
    expect(id3v2_tag["TYER"].detect { |frame|
      frame.value == "2002"
    }).to be_truthy
  end
end
