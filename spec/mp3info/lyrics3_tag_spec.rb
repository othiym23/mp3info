require "mp3info/lyrics3_tag"

describe Lyrics3Tag do
  context "with a file containing a Lyrics3v2 tag" do
    before :each do
      @filename = "test_lyrics3v2.mp3"
      audio_data = "\xFF\xFB\x90\x64".b + ("\x00" * 413).b
      lyrics_body = "LYRICSBEGIN" + ("x" * 100)
      size_field = "%06d" % (lyrics_body.size + 6 + 9) # size includes size field + end marker
      File.binwrite(@filename, audio_data + lyrics_body + size_field + "LYRICS200")
    end

    after :each do
      FileUtils.rm_f(@filename)
    end

    it "detects the Lyrics3v2 tag" do
      tag = Lyrics3Tag.detect(@filename)
      expect(tag).not_to be_nil
      expect(tag.version).to eq(2)
    end

    it "reads the size" do
      tag = Lyrics3Tag.detect(@filename)
      expect(tag.size).to eq(126)
    end

    it "produces a string representation" do
      tag = Lyrics3Tag.detect(@filename)
      expect(tag.to_s).to include("Lyrics3v2")
      expect(tag.to_s).to include("bytes")
    end
  end

  context "with a file containing a Lyrics3v1 tag" do
    before :each do
      @filename = "test_lyrics3v1.mp3"
      audio_data = "\xFF\xFB\x90\x64".b + ("\x00" * 413).b
      lyrics_body = "LYRICSBEGIN" + ("Hello World " * 10)
      File.binwrite(@filename, audio_data + lyrics_body + "LYRICSEND")
    end

    after :each do
      FileUtils.rm_f(@filename)
    end

    it "detects the Lyrics3v1 tag" do
      tag = Lyrics3Tag.detect(@filename)
      expect(tag).not_to be_nil
      expect(tag.version).to eq(1)
    end

    it "calculates the tag size" do
      tag = Lyrics3Tag.detect(@filename)
      # LYRICSBEGIN(11) + "Hello World "(12)*10 + LYRICSEND(9) = 140
      expect(tag.size).to eq(140)
    end

    it "produces a string representation" do
      tag = Lyrics3Tag.detect(@filename)
      expect(tag.to_s).to include("Lyrics3v1")
    end
  end

  context "with a file containing a Lyrics3v2 tag before ID3v1" do
    before :each do
      @filename = "test_lyrics3v2_id3v1.mp3"
      audio_data = "\xFF\xFB\x90\x64".b + ("\x00" * 413).b
      lyrics_body = "LYRICSBEGIN" + ("y" * 50)
      size_field = "%06d" % (lyrics_body.size + 6 + 9)
      id3v1 = "TAG" + ("\x00" * 125)
      File.binwrite(@filename, audio_data + lyrics_body + size_field + "LYRICS200" + id3v1)
    end

    after :each do
      FileUtils.rm_f(@filename)
    end

    it "detects the Lyrics3v2 tag before ID3v1" do
      tag = Lyrics3Tag.detect(@filename)
      expect(tag).not_to be_nil
      expect(tag.version).to eq(2)
    end
  end

  context "with a file without a Lyrics3 tag" do
    before :each do
      @filename = "test_no_lyrics3.mp3"
      audio_data = "\xFF\xFB\x90\x64".b + ("\x00" * 413).b
      File.binwrite(@filename, audio_data)
    end

    after :each do
      FileUtils.rm_f(@filename)
    end

    it "returns nil" do
      tag = Lyrics3Tag.detect(@filename)
      expect(tag).to be_nil
    end
  end
end
