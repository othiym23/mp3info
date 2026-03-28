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
    expect(@tag.version).to eq("2.3.0")
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

  it "should parse a v2.3 extended header with CRC" do
    # v2.3 extended header: 4-byte size (big-endian) + flags + padding size + CRC
    # size = 10 (2 flag bytes + 4 padding bytes + 4 CRC bytes)
    ext_size = [10].pack("N")
    ext_flags = "\x80\x00".b  # CRC flag set
    ext_padding = [0].pack("N")
    ext_crc = [0xDEADBEEF].pack("N")
    ext_header = (ext_size + ext_flags + ext_padding + ext_crc).b

    frame_data = "\x03Test".b
    frame = ("TIT2" + [frame_data.bytesize].pack("N") + "\x00\x00".b + frame_data).b

    tag_body = ext_header + frame
    tag_size = tag_body.bytesize.to_synchsafe_string
    tag_string = ("ID3\x03\x00\x40".b + tag_size + tag_body).b

    @tag.from_bin(tag_string)
    expect(@tag["TIT2"].value).to eq("Test")
    expect(@tag.extended_header).not_to be_nil
    expect(@tag.extended_header[:has_crc]).to be true
    expect(@tag.extended_header[:crc]).to eq(0xDEADBEEF)
    expect(@tag.extended_header[:padding_size]).to eq(0)
  end

  it "should parse a v2.4 extended header with restrictions" do
    # v2.4 extended header: synchsafe size (includes 4 size bytes), flag byte count, flags, flag data
    # Restrictions flag: 0x10
    restrictions_byte = 0b00110001  # some restriction bits set
    # Layout: [4 synchsafe size] [1 flag count] [1 flags] [1 restrictions length=0x01] [1 restrictions]
    ext_body = "\x01"           # number of flag bytes
    ext_body << "\x10"          # flags: restrictions
    ext_body << "\x01"          # restrictions data length
    ext_body << restrictions_byte.chr
    ext_total_size = (4 + ext_body.bytesize)  # size includes the 4 size bytes
    ext_header = ext_total_size.to_synchsafe_string + ext_body

    frame_data = "\x03Test"
    frame = "TIT2" + frame_data.bytesize.to_synchsafe_string + "\x00\x00" + frame_data

    tag_body = ext_header + frame
    tag_size = tag_body.bytesize.to_synchsafe_string
    tag_string = "ID3\x04\x00\x40" + tag_size + tag_body

    @tag.from_bin(tag_string.dup.force_encoding("BINARY"))
    expect(@tag["TIT2"].value).to eq("Test")
    expect(@tag.extended_header).not_to be_nil
    expect(@tag.extended_header[:has_restrictions]).to be true
    expect(@tag.extended_header[:restrictions]).to eq(restrictions_byte)
  end

  it "should decompress a zlib-compressed frame in v2.3" do
    require "zlib"
    # Original frame body: encoding byte + text
    original_body = "\x03Hello Compressed World".b
    compressed_body = Zlib::Deflate.deflate(original_body)

    # v2.3 compressed frame: flags byte 2 bit 7 = 0x80
    # Extra header: 4-byte decompressed size (big-endian)
    decompressed_size = [original_body.bytesize].pack("N")
    frame_content = (decompressed_size + compressed_body).b
    frame = ("TIT2" + [frame_content.bytesize].pack("N") + "\x00\x80".b + frame_content).b

    # Also add a normal frame to verify parsing continues
    frame2_data = "\x03Artist".b
    frame2 = ("TPE1" + [frame2_data.bytesize].pack("N") + "\x00\x00".b + frame2_data).b

    tag_body = frame + frame2
    tag_size = tag_body.bytesize.to_synchsafe_string
    tag_string = ("ID3\x03\x00\x00".b + tag_size + tag_body).b

    @tag.from_bin(tag_string)
    expect(@tag["TIT2"].value).to eq("Hello Compressed World")
    expect(@tag["TPE1"].value).to eq("Artist")
  end

  it "should handle per-frame unsynchronization in v2.4" do
    # Use a PRIV frame to test raw binary de-unsynchronization.
    # The real data should contain \xFF\xFB after de-unsync.
    # Unsync encoding turns \xFF\xFB into \xFF\x00\xFB.
    owner = "test".b
    real_data = "\xFF\xFB\x90\x00".b
    unsync_data = "\xFF\x00\xFB\x90\x00".b
    unsync_body = (owner + "\x00".b + unsync_data).b

    # v2.4 frame unsync flag: byte 2 bit 1 = 0x02
    frame_size = unsync_body.bytesize.to_synchsafe_string
    frame = ("PRIV".b + frame_size + "\x00\x02".b + unsync_body).b

    tag_body = frame
    tag_size = tag_body.bytesize.to_synchsafe_string
    tag_string = ("ID3\x04\x00\x00".b + tag_size + tag_body).b

    @tag.from_bin(tag_string)
    priv = @tag["PRIV"]
    expect(priv.owner).to eq("test")
    # The value should have \xFF\x00 replaced with \xFF, yielding original data
    expect(priv.value.b).to eq(real_data)
  end

  it "should apply per-frame unsynchronization when writing v2.4 with sync-like data" do
    @tag.write_version = 4
    # PRIV frame with data containing \xFF\xFB (looks like MPEG sync)
    sync_data = "test\x00\xFF\xFB\x90\x00".b
    @tag["PRIV"] = ID3V24::Frame.create_frame_from_string("PRIV", sync_data)

    bin = @tag.to_bin
    # The per-frame unsync flag (byte 2, bit 1) should be set
    # Find the PRIV frame in the output
    priv_pos = bin.index("PRIV")
    expect(priv_pos).not_to be_nil
    frame_flags_byte = bin[priv_pos + 4 + 4 + 1].ord  # after name(4) + size(4) + status(1)
    expect(frame_flags_byte & 0x02).to eq(0x02)

    # Round-trip: parse the binary back and verify data is intact
    tag2 = ID3V2.new
    tag2.from_bin(bin)
    expect(tag2["PRIV"].value.b).to eq("\xFF\xFB\x90\x00".b)
  end

  it "should not apply unsynchronization for v2.3 output" do
    @tag.write_version = 3
    sync_data = "test\x00\xFF\xFB\x90\x00".b
    @tag["PRIV"] = ID3V24::Frame.create_frame_from_string("PRIV", sync_data)

    bin = @tag.to_bin
    # Tag-level unsync flag should NOT be set
    expect(bin[5].ord & 0x80).to eq(0)

    # Round-trip
    tag2 = ID3V2.new
    tag2.from_bin(bin)
    expect(tag2["PRIV"].value.b).to eq("\xFF\xFB\x90\x00".b)
  end
end
