using Mp3InfoLib::BinaryConversions

describe ID3V2, "when creating ID3v2 tags" do
  before do
    @tag = ID3V2.new
  end

  it "should create a tag that is valid by default" do
    expect(@tag.valid?).to be true
  end

  it "should create a tag with a major version of 3 by default" do
    expect(@tag.major_version).to eq(3)
  end

  it "should create a tag with a minor version of 0 by default" do
    expect(@tag.minor_version).to eq(0)
  end

  it "should create a tag with a full version of '2.3.0' by default" do
    expect(@tag.version).to eq('2.3.0')
  end

  it "should create a tag without unsynchronized frames by default" do
    expect(@tag.unsynchronized?).to be false
  end

  it "should create a tag with no extended header by default" do
    expect(@tag.extended_header?).to be false
  end

  it "should create tags that are not experimental (as if) by default" do
    expect(@tag.experimental?).to be false
  end

  it "should create a tag that does not have footers by default" do
    expect(@tag.footer?).to be false
  end

  it "should recognize an empty ID3v2.2 tag" do
    tag_string = "ID3\x02\x00\x00\x00\x00\x00\x00"
    @tag.from_bin(tag_string)
    expect(@tag.valid?).to be true
    expect(@tag.major_version).to eq(2)
    expect(@tag.minor_version).to eq(0)
    expect(@tag.version).to eq("2.2.0")
  end

  it "should be able to dump and then read a tag using bare-bones file operations" do
    filename = "sample_tag.id3"
    @tag.update(sample_id3v2_tag)
    @tag.to_file(filename)
    expect(ID3V2.from_file(filename)).to eq(sample_id3v2_tag)
    FileUtils.rm_f(filename)
  end

  it "should skip the extended header in an ID3v2.3 tag" do
    # Build a v2.3 tag with extended header flag set (byte 5 = 0x40)
    # Extended header: 4-byte size (big-endian, not synchsafe) + that many bytes of data
    ext_header_data = "\x00" * 6  # 6 bytes of extended header data
    ext_header = [ext_header_data.bytesize].pack("N") + ext_header_data  # 4 + 6 = 10 bytes

    # A simple TIT2 frame: 4-byte name + 4-byte size + 2-byte flags + data
    frame_data = "\x03Test"  # UTF-8 encoding byte + "Test"
    frame = "TIT2" + [frame_data.bytesize].pack("N") + "\x00\x00" + frame_data

    tag_body = ext_header + frame
    tag_size = tag_body.bytesize.to_synchsafe_string
    tag_string = "ID3\x03\x00\x40" + tag_size + tag_body

    @tag.from_bin(tag_string.dup.force_encoding("BINARY"))
    expect(@tag["TIT2"].value).to eq("Test")
  end

  it "should skip the extended header in an ID3v2.4 tag" do
    # Build a v2.4 tag with extended header flag set (byte 5 = 0x40)
    # v2.4 extended header: 4-byte synchsafe size (includes the 4 size bytes)
    ext_total_size = 10  # 4 size bytes + 6 bytes of data
    ext_header = ext_total_size.to_synchsafe_string + "\x00" * 6

    # A simple TIT2 frame with synchsafe size
    frame_data = "\x03Test"
    frame = "TIT2" + frame_data.bytesize.to_synchsafe_string + "\x00\x00" + frame_data

    tag_body = ext_header + frame
    tag_size = tag_body.bytesize.to_synchsafe_string
    tag_string = "ID3\x04\x00\x40" + tag_size + tag_body

    @tag.from_bin(tag_string.dup.force_encoding("BINARY"))
    expect(@tag["TIT2"].value).to eq("Test")
  end

  it "should skip compressed frames in an ID3v2.3 tag" do
    # Frame 1: TIT2 with compression flag set (flag byte 2, bit 7 = 0x80)
    compressed_data = "\x00" * 10
    frame1 = "TIT2" + [compressed_data.bytesize].pack("N") + "\x00\x80" + compressed_data

    # Frame 2: TPE1 normal frame
    frame2_data = "\x03Artist"
    frame2 = "TPE1" + [frame2_data.bytesize].pack("N") + "\x00\x00" + frame2_data

    tag_body = frame1 + frame2
    tag_size = tag_body.bytesize.to_synchsafe_string
    tag_string = "ID3\x03\x00\x00" + tag_size + tag_body

    @tag.from_bin(tag_string.dup.force_encoding("BINARY"))
    expect(@tag["TIT2"]).to be_nil
    expect(@tag["TPE1"].value).to eq("Artist")
  end

  it "should skip encrypted frames in an ID3v2.4 tag" do
    # Frame 1: TIT2 with encryption flag set (flag byte 2, bit 2 = 0x04)
    encrypted_data = "\x00" * 10
    frame1 = "TIT2" + encrypted_data.bytesize.to_synchsafe_string + "\x00\x04" + encrypted_data

    # Frame 2: TPE1 normal frame
    frame2_data = "\x03Artist"
    frame2 = "TPE1" + frame2_data.bytesize.to_synchsafe_string + "\x00\x00" + frame2_data

    tag_body = frame1 + frame2
    tag_size = tag_body.bytesize.to_synchsafe_string
    tag_string = "ID3\x04\x00\x00" + tag_size + tag_body

    @tag.from_bin(tag_string.dup.force_encoding("BINARY"))
    expect(@tag["TIT2"]).to be_nil
    expect(@tag["TPE1"].value).to eq("Artist")
  end
end
