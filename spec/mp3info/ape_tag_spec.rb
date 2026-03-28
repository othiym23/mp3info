require "mp3info/ape_tag"

describe APETag do
  def build_ape_footer(version: 2000, tag_size: 256, item_count: 5, flags: 0)
    footer = "APETAGEX".b
    footer += [version].pack("V") # little-endian 32-bit
    footer += [tag_size].pack("V")
    footer += [item_count].pack("V")
    footer += [flags].pack("V")
    footer += ("\x00" * 8).b # reserved
    footer
  end

  context "with a file containing an APEv2 footer" do
    before :each do
      @filename = "test_ape_tag.mp3"
      audio_data = "\xFF\xFB\x90\x64".b + ("\x00" * 413).b
      File.binwrite(@filename, audio_data + build_ape_footer)
    end

    after :each do
      FileUtils.rm_f(@filename)
    end

    it "detects the APE tag" do
      tag = APETag.detect(@filename)
      expect(tag).not_to be_nil
    end

    it "reads the version" do
      tag = APETag.detect(@filename)
      expect(tag.version).to eq(2000)
    end

    it "identifies as APEv2" do
      tag = APETag.detect(@filename)
      expect(tag.apev2?).to be true
      expect(tag.apev1?).to be false
    end

    it "reads the item count" do
      tag = APETag.detect(@filename)
      expect(tag.item_count).to eq(5)
    end

    it "reads the tag size" do
      tag = APETag.detect(@filename)
      expect(tag.tag_size).to eq(256)
    end

    it "produces a string representation" do
      tag = APETag.detect(@filename)
      expect(tag.to_s).to include("APEv2")
      expect(tag.to_s).to include("5 items")
    end
  end

  context "with a file containing an APEv1 footer" do
    before :each do
      @filename = "test_ape_v1_tag.mp3"
      audio_data = "\xFF\xFB\x90\x64".b + ("\x00" * 413).b
      File.binwrite(@filename, audio_data + build_ape_footer(version: 1000))
    end

    after :each do
      FileUtils.rm_f(@filename)
    end

    it "identifies as APEv1" do
      tag = APETag.detect(@filename)
      expect(tag.apev1?).to be true
      expect(tag.apev2?).to be false
    end
  end

  context "with a file containing an APE footer before ID3v1" do
    before :each do
      @filename = "test_ape_before_id3v1.mp3"
      audio_data = "\xFF\xFB\x90\x64".b + ("\x00" * 413).b
      id3v1 = "TAG" + ("\x00" * 125)
      File.binwrite(@filename, audio_data + build_ape_footer + id3v1)
    end

    after :each do
      FileUtils.rm_f(@filename)
    end

    it "detects the APE tag before ID3v1" do
      tag = APETag.detect(@filename)
      expect(tag).not_to be_nil
      expect(tag.version).to eq(2000)
    end
  end

  context "with a file containing an APE footer with header flag" do
    before :each do
      @filename = "test_ape_with_header.mp3"
      audio_data = "\xFF\xFB\x90\x64".b + ("\x00" * 413).b
      File.binwrite(@filename, audio_data + build_ape_footer(flags: 0x80000000))
    end

    after :each do
      FileUtils.rm_f(@filename)
    end

    it "detects the header flag" do
      tag = APETag.detect(@filename)
      expect(tag.has_header?).to be true
    end
  end

  context "with a file without an APE tag" do
    before :each do
      @filename = "test_no_ape_tag.mp3"
      audio_data = "\xFF\xFB\x90\x64".b + ("\x00" * 413).b
      File.binwrite(@filename, audio_data)
    end

    after :each do
      FileUtils.rm_f(@filename)
    end

    it "returns nil" do
      tag = APETag.detect(@filename)
      expect(tag).to be_nil
    end
  end
end
