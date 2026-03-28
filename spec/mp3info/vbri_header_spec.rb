require "mp3info/binary_conversions"
require "mp3info/size_units"
require "mp3info/vbri_header"

using Mp3InfoLib::BinaryConversions
using Mp3InfoLib::SizeUnits

describe VBRIHeader do
  def build_vbri_frame(
    version: 1,
    delay: 0,
    quality: 75,
    bytes: 123_456,
    frames: 1000,
    toc_entries: 100,
    toc_scale: 1,
    toc_entry_size: 2,
    toc_frames_per_entry: 10
  )
    # Build a frame with VBRI header at offset 36
    frame = "\xFF\xFB\x90\x64".b # valid MPEG header
    frame += ("\x00" * 32).b # padding to reach offset 36
    frame += "VBRI".b # tag identifier
    frame += [version].pack("n") # version (big-endian 16-bit)
    frame += [delay].pack("n") # delay (big-endian 16-bit)
    frame += [quality].pack("n") # quality (big-endian 16-bit)
    frame += [bytes].pack("N") # bytes (big-endian 32-bit)
    frame += [frames].pack("N") # frames (big-endian 32-bit)
    frame += [toc_entries].pack("n") # TOC entries (big-endian 16-bit)
    frame += [toc_scale].pack("n") # TOC scale (big-endian 16-bit)
    frame += [toc_entry_size].pack("n") # TOC entry size (big-endian 16-bit)
    frame += [toc_frames_per_entry].pack("n") # frames per TOC entry (big-endian 16-bit)
    frame += ("\x00" * (toc_entries * toc_entry_size)).b # TOC data
    frame
  end

  context "with a valid VBRI header" do
    before :each do
      @frame = build_vbri_frame
      @header = VBRIHeader.new(@frame)
    end

    it "is valid" do
      expect(@header.valid?).to be true
    end

    it "reads the version" do
      expect(@header.version).to eq(1)
    end

    it "reads the quality" do
      expect(@header.quality).to eq(75)
    end

    it "reads the byte count" do
      expect(@header.bytes).to eq(123_456)
    end

    it "reads the frame count" do
      expect(@header.frames).to eq(1000)
    end

    it "reads the TOC entries count" do
      expect(@header.toc_entries).to eq(100)
    end

    it "reads the TOC scale" do
      expect(@header.toc_scale).to eq(1)
    end

    it "reads the TOC entry size" do
      expect(@header.toc_entry_size).to eq(2)
    end

    it "reads the frames per TOC entry" do
      expect(@header.toc_frames_per_entry).to eq(10)
    end

    it "produces a string representation" do
      expect(@header.to_s).to include("VBRI")
      expect(@header.to_s).to include("1000")
    end

    it "produces a description" do
      desc = @header.description
      expect(desc).to include("VBRI header")
      expect(desc).to include("valid")
      expect(desc).to include("75")
    end
  end

  context "with different values" do
    it "reads custom byte and frame counts" do
      frame = build_vbri_frame(bytes: 5_000_000, frames: 4200, quality: 50)
      header = VBRIHeader.new(frame)
      expect(header.bytes).to eq(5_000_000)
      expect(header.frames).to eq(4200)
      expect(header.quality).to eq(50)
    end
  end

  context "with an invalid frame" do
    it "is not valid when frame is too short" do
      header = VBRIHeader.new("\xFF\xFB\x90\x64".b + ("\x00" * 10).b)
      expect(header.valid?).to be false
    end

    it "is not valid when VBRI tag is missing" do
      frame = "\xFF\xFB\x90\x64".b + ("\x00" * 100).b
      header = VBRIHeader.new(frame)
      expect(header.valid?).to be false
    end
  end
end
