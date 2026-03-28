$:.unshift("spec/")

require 'digest/sha1'
require 'mp3info/mp3info_helper'

describe Mp3Info, "when working with ID3v2 tags" do
  include Mp3InfoHelper

  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)

    @trivial_id3v2_tag = {"TIT2" => ID3V24::Frame.create_frame('TIT2', "sdfqdsf")}
  end

  after do
    FileUtils.rm_f(@mp3_filename)
  end

  it "should be able to add the tag without error" do
    finish_tag = {}
    expect { finish_tag = update_id3_2_tag(@mp3_filename, @trivial_id3v2_tag) }.not_to raise_error
    expect(finish_tag).to eq(@trivial_id3v2_tag)
  end

  it "should be able to add and remove the tag without error" do
    file_size = File.stat(@mp3_filename).size
    update_id3_2_tag(@mp3_filename, @trivial_id3v2_tag)
    expect(File.stat(@mp3_filename).size).to be > file_size

    expect(ID3V2.has_id3v2_tag?(@mp3_filename)).to be true
    ID3V2.remove_id3v2_tag!(@mp3_filename)
    expect(ID3V2.has_id3v2_tag?(@mp3_filename)).to be false
  end

  it "should be able to add the tag and then remove it from within the open() block" do
    update_id3_2_tag(@mp3_filename, @trivial_id3v2_tag)

    expect(ID3V2.has_id3v2_tag?(@mp3_filename)).to be true
    expect { Mp3Info.open(@mp3_filename) { |info| info.remove_id3v2_tag } }.not_to raise_error
    expect(ID3V2.has_id3v2_tag?(@mp3_filename)).to be false
  end

  it "should not have a tag until one is automatically created" do
    mp3 = Mp3Info.new(@mp3_filename)
    expect(mp3.has_id3v2_tag?).to be false
    mp3.id3v2_tag['TPE1'] = 'The Mighty Boosh'
    expect(mp3.has_id3v2_tag?).to be true
    expect(mp3.id3v2_tag['TPE1'].value).to eq('The Mighty Boosh')
  end

  it "should create ID3v2.4.0 tags by default" do
    mp3 = Mp3Info.new(@mp3_filename)
    expect(mp3.has_id3v2_tag?).to be false
    mp3.id3v2_tag['TRCK'] = "1/8"
    expect(mp3.has_id3v2_tag?).to be true
    expect(mp3.id3v2_tag.version).to eq("2.4.0")
  end

  it "should be able to discover the version of the ID3v2 tag written to disk" do
    expect(update_id3_2_tag(@mp3_filename, sample_id3v2_tag).version).to eq("2.4.0")
  end

  it "should handle storing and retrieving tags containing arbitrary binary data" do
    tag = {}
    ["PRIV", "XNBC", "APIC", "XNXT"].each do |k|
      tag[k] = ID3V24::Frame.create_frame(k, random_string)
    end

    expect { expect(update_id3_2_tag(@mp3_filename, tag)).to eq(tag) }.not_to raise_error
  end

  it "should handle storing tags via the tag update mechanism in mp3info's open() block" do
    tag = {}
    ["PRIV", "XNBC", "APIC", "XNXT"].each do |k|
      tag[k] = ID3V24::Frame.create_frame(k, random_string)
    end

    Mp3Info.open(@mp3_filename) do |mp3|
      # before update
      expect(mp3.has_id3v2_tag?).to be false
      mp3.id3v2_tag = ID3V2.new
      mp3.id3v2_tag.update(tag)
    end

    # after update has been saved
    Mp3Info.open(@mp3_filename) do |saved|
      ["PRIV", "XNBC", "APIC", "XNXT"].each do |k|
        expect(saved.id3v2_tag[k]).not_to be_nil
        expect(Digest::SHA1.hexdigest(tag[k].value)).to eq(Digest::SHA1.hexdigest(saved.id3v2_tag[k].value))
      end
    end
  end

  it "should read an ID3v2 tag from a truncated MP3 file" do
    expect { mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/zovietfrance/Popular Soviet Songs And Youth Music disc 3/zovietfrance - Popular Soviet Songs And Youth Music - 08 - Shewel.mp3')) }.not_to raise_error
  end

  it "should still read the tag from a truncated MP3 file" do
    expect { mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/id3lib/230-unicode.tag')) }.not_to raise_error
  end

  it "should default to not exposing the ID3v2 tag for casual use until it's had a frame added" do
    Mp3Info.open(@mp3_filename) do |mp3|
      expect(mp3.has_id3v2_tag?).to be false
    end
  end

  it "should write synchsafe frame sizes even when the source tag was v2.3" do
    # Create a v2.3 tag (non-synchsafe frame sizes) by hand
    v23_tag = "ID3"
    v23_tag << [3, 0, 0].pack("CCC")  # v2.3.0, no flags
    frame_data = "\x03Test Title\x00"  # UTF-8 encoding byte + text + null
    frame = "TIT2"
    frame << [frame_data.bytesize].pack("N")  # v2.3: non-synchsafe 4-byte size
    frame << "\x00\x00"  # frame flags
    frame << frame_data
    v23_tag << (frame.bytesize).to_synchsafe_string
    v23_tag << frame

    File.open(@mp3_filename, 'wb') do |f|
      f.write(v23_tag)
      f.write(get_valid_mp3)
    end

    # Read and modify the tag
    Mp3Info.open(@mp3_filename) do |mp3|
      mp3.id3v2_tag['TPE1'] = 'Test Artist'
    end

    # Verify the written tag has synchsafe frame sizes
    raw = File.binread(@mp3_filename)
    expect(raw[0, 3]).to eq('ID3')
    expect(raw[3].ord).to eq(4)  # should be upgraded to v2.4

    # Parse the tag and verify frame sizes are synchsafe
    tag_size = raw[6, 4].from_synchsafe_string
    tag_data = raw[10, tag_size]
    pos = 0
    while pos + 10 <= tag_data.bytesize
      name = tag_data[pos, 4]
      break unless name.match?(/\A[A-Z0-9]{4}\z/)
      size_bytes = tag_data[pos + 4, 4]
      expect(size_bytes.synchsafe?).to be(true), "Frame #{name} at offset #{pos} has non-synchsafe size"
      size = size_bytes.from_synchsafe_string
      pos += 10 + size
    end
  end

  it "should make it easy to casually use ID3v2 tags" do
    Mp3Info.open(@mp3_filename) do |mp3|
      mp3.id3v2_tag = ID3V2.new
      mp3.id3v2_tag['WCOM'] = "http://www.riaa.org/"
      mp3.id3v2_tag['TXXX'] = "A sample comment"
    end

    mp3 = Mp3Info.new(@mp3_filename)
    saved_tag = mp3.id3v2_tag

    expect(saved_tag['WCOM'].value).to eq("http://www.riaa.org/")
    expect(saved_tag['TXXX'].value).to eq("A sample comment")
  end
end
