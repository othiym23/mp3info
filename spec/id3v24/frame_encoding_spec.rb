describe ID3V24::Frame, "when dealing with the various frame encoding types" do
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end

  after do
    FileUtils.rm_f(@mp3_filename)
  end

  it "should correctly handle ISO 8859-1 text" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Junior Citizen (lé Freak!)")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:iso]
    tag = {"TIT2" => tit2}
    saved_tag = update_id3_2_tag(@mp3_filename, tag)

    # ID3V24::TextFrame::ENCODING[:iso] => 0
    expect(saved_tag["TIT2"].encoding).to eq(0)
    expect(saved_tag["TIT2"].encoding).to eq(ID3V24::TextFrame::ENCODING[:iso])
    expect(saved_tag["TIT2"].value).to eq("Junior Citizen (lé Freak!)")
  end

  it "should correctly handle UTF-16 Unicode text with a byte-order mark" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:utf16]
    tag = {"TIT2" => tit2}
    saved_tag = update_id3_2_tag(@mp3_filename, tag)

    # ID3V24::TextFrame::ENCODING[:utf16] => 1
    expect(saved_tag["TIT2"].encoding).to eq(1)
    expect(saved_tag["TIT2"].encoding).to eq(ID3V24::TextFrame::ENCODING[:utf16])
    expect(saved_tag["TIT2"].value).to eq("Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
  end

  it "should correctly handle big-endian UTF-16 Unicode text" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:utf16be]
    tag = {"TIT2" => tit2}
    saved_tag = update_id3_2_tag(@mp3_filename, tag)

    # ID3V24::TextFrame::ENCODING[:utf16be] => 2
    expect(saved_tag["TIT2"].encoding).to eq(2)
    expect(saved_tag["TIT2"].encoding).to eq(ID3V24::TextFrame::ENCODING[:utf16be])
    expect(saved_tag["TIT2"].value).to eq("Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
  end

  it "should correctly handle UTF-8 Unicode text" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:utf8]
    tag = {"TIT2" => tit2}
    saved_tag = update_id3_2_tag(@mp3_filename, tag)

    # ID3V24::TextFrame::ENCODING[:utf8] => 3
    expect(saved_tag["TIT2"].encoding).to eq(3)
    expect(saved_tag["TIT2"].encoding).to eq(ID3V24::TextFrame::ENCODING[:utf8])
    expect(saved_tag["TIT2"].value).to eq("Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
  end

  it "should raise a conversion error when trying to save Unicode text in an ISO 8859-1-encoded frame" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:iso]
    tag = {"TIT2" => tit2}
    expect { update_id3_2_tag(@mp3_filename, tag) }.to raise_error(Encoding::UndefinedConversionError)
  end

  it "should correctly split UTF-16 strings containing characters with null bytes" do
    # UTF-16BE for "A" is \x00\x41, which contains a \x00 byte
    # Description "A" + null terminator + value "B"
    # In UTF-16BE: \x00\x41 \x00\x00 \x00\x42
    raw = "\x00\x41\x00\x00\x00\x42".b
    prefix, remainder = ID3V24::TextFrame.send(:split_encoded, ID3V24::TextFrame::ENCODING[:utf16be], raw)
    expect(prefix).to eq("\x00\x41".b)
    expect(remainder).to eq("\x00\x42".b)
  end

  it "should handle malformed UTF-16 data without crashing" do
    # Odd number of bytes — invalid UTF-16
    malformed = "\xFF\xFE\x41".b
    expect { ID3V24::TextFrame.from_s("\x01#{malformed}", "TIT2") }.not_to raise_error
  end

  it "should handle malformed UTF-8 data without crashing" do
    # Invalid UTF-8 continuation byte
    malformed = "\xFF\xFE".b
    expect { ID3V24::TextFrame.from_s("\x03#{malformed}", "TIT2") }.not_to raise_error
  end

  it "should correctly split UTF-16LE strings with BOM containing characters with null bytes" do
    # UTF-16 with LE BOM: \xFF\xFE
    # Description "A" (\x41\x00) + null terminator (\x00\x00) + value "B" (\x42\x00)
    raw = "\xFF\xFE\x41\x00\x00\x00\x42\x00".b
    prefix, remainder = ID3V24::TextFrame.send(:split_encoded, ID3V24::TextFrame::ENCODING[:utf16], raw)
    # prefix should include the BOM and the character
    expect(prefix).to eq("\xFF\xFE\x41\x00".b)
    expect(remainder).to eq("\x42\x00".b)
  end
end
