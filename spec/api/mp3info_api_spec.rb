require "fileutils"

describe "Mp3Info Public API" do
  let(:sample_path) { File.join(__dir__, "../../sample-metadata/Wire/Chairs Missing [Japanese version]/Wire - Chairs Missing [Japanese version] - 01 - Practice Makes Perfect.mp3") }
  let(:mp3) { Mp3Info.new(sample_path) }
  let(:tmp) { "api_test_#{$$}.mp3" }

  after { FileUtils.rm_f(tmp) }

  describe ".open" do
    it "yields an Mp3Info and auto-closes" do
      create_sample_mp3_file(tmp)
      title = nil
      Mp3Info.open(tmp) do |m|
        m.id3v2_tag["TIT2"] = "Test"
        title = m.id3v2_tag["TIT2"].value
      end
      expect(title).to eq("Test")
    end

    it "returns the block's value" do
      create_sample_mp3_file(tmp)
      result = Mp3Info.open(tmp) { |m| m.has_mpeg_header? }
      expect(result).to be true
    end

    it "returns the Mp3Info if no block given" do
      create_sample_mp3_file(tmp)
      m = Mp3Info.open(tmp)
      expect(m).to be_a(Mp3Info)
    end
  end

  describe ".remove_id3v1_tag / .remove_id3v2_tag" do
    it "removes tags by filename without opening" do
      create_sample_mp3_file(tmp)
      Mp3Info.open(tmp) { |m| m.id3v2_tag["TIT2"] = "X" }
      expect(ID3V2.has_id3v2_tag?(tmp)).to be true
      Mp3Info.remove_id3v2_tag(tmp)
      expect(ID3V2.has_id3v2_tag?(tmp)).to be false
    end
  end

  describe "metadata accessors" do
    it "#mpeg_header returns MPEG frame information" do
      expect(mp3.mpeg_header).to be_a(MPEGHeader)
      expect(mp3.mpeg_header.version).to eq(1.0)
      expect(mp3.mpeg_header.layer).to eq(3)
      expect(mp3.mpeg_header.sample_rate).to eq(44_100)
    end

    it "#bitrate returns kbps (VBR average or CBR)" do
      expect(mp3.bitrate).to be_a(Integer)
      expect(mp3.bitrate).to be > 0
    end

    it "#vbr? detects variable bitrate" do
      expect(mp3.vbr?).to be(true).or be(false)
    end

    it "#to_s returns a human-readable summary" do
      expect(mp3.to_s).to match(/MPEG/)
    end

    it "#duration_string returns formatted duration" do
      expect(mp3.duration_string).to match(/\d+:\d{2}/)
    end
  end

  describe "predicate methods" do
    it "reports which headers and tags are present" do
      expect(mp3.has_mpeg_header?).to be true
      expect(mp3.has_id3v2_tag?).to be true
      # These may or may not be present depending on the file
      [mp3.has_id3v1_tag?, mp3.has_xing_header?, mp3.has_lame_header?,
        mp3.has_vbri_header?, mp3.has_ape_tag?, mp3.has_lyrics3_tag?].each do |val|
        expect(val).to be(true).or be(false)
      end
    end
  end

  describe "#tag (universal tag)" do
    it "provides a simple hash of common fields regardless of tag version" do
      expect(mp3.tag).to be_a(Hash)
      expect(mp3.tag["title"]).to be_a(String)
      expect(mp3.tag["artist"]).to be_a(String)
    end
  end

  describe "reading and writing ID3v2 tags" do
    it "reads and writes text frames" do
      create_sample_mp3_file(tmp)
      Mp3Info.open(tmp) do |m|
        m.id3v2_tag["TIT2"] = "New Title"
        m.id3v2_tag["TPE1"] = "New Artist"
      end

      m = Mp3Info.new(tmp)
      expect(m.id3v2_tag["TIT2"].value).to eq("New Title")
      expect(m.id3v2_tag["TPE1"].value).to eq("New Artist")
    end

    it "reads and writes comment frames" do
      create_sample_mp3_file(tmp)
      Mp3Info.open(tmp) do |m|
        comm = ID3V24::Frame.create_frame("COMM", "A comment")
        m.id3v2_tag["COMM"] = comm
      end

      m = Mp3Info.new(tmp)
      expect(m.id3v2_tag["COMM"].value).to eq("A comment")
      expect(m.id3v2_tag["COMM"].language).to eq("eng")
    end

    it "reads and writes picture frames" do
      create_sample_mp3_file(tmp)
      picture_data = "\xFF\xD8\xFF\xE0" + ("\x00" * 50) # fake JPEG
      Mp3Info.open(tmp) do |m|
        m.id3v2_tag["APIC"] = ID3V24::APICFrame.new(
          ID3V24::TextFrame::ENCODING[:utf8],
          "image/jpeg", "\x03", "cover", picture_data
        )
      end

      m = Mp3Info.new(tmp)
      expect(m.id3v2_tag["APIC"]).to be_a(ID3V24::APICFrame)
      expect(m.id3v2_tag["APIC"].mime_type).to eq("image/jpeg")
      expect(m.id3v2_tag["APIC"].value.bytesize).to eq(54)
    end

    it "supports multiple frames with the same key" do
      create_sample_mp3_file(tmp)
      Mp3Info.open(tmp) do |m|
        m.id3v2_tag["COMM"] = [
          ID3V24::COMMFrame.new(3, "eng", "", "Comment 1"),
          ID3V24::COMMFrame.new(3, "eng", "desc", "Comment 2")
        ]
      end

      m = Mp3Info.new(tmp)
      # [] returns array when multiple frames exist
      expect(m.id3v2_tag["COMM"]).to be_a(Array)
      expect(m.id3v2_tag["COMM"].size).to eq(2)
      # frames() always returns array
      expect(m.id3v2_tag.frames("COMM")).to be_a(Array)
    end

    it "controls output version with write_version" do
      create_sample_mp3_file(tmp)
      Mp3Info.open(tmp) do |m|
        m.id3v2_tag.write_version = 4
        m.id3v2_tag["TIT2"] = "v2.4 Tag"
      end

      m = Mp3Info.new(tmp)
      expect(m.id3v2_tag.version).to eq("2.4.0")
    end
  end

  describe "reading and writing ID3v1 tags" do
    it "reads and writes ID3v1.1 fields" do
      create_sample_mp3_file(tmp)
      Mp3Info.open(tmp) do |m|
        m.id3v1_tag["title"] = "My Song"
        m.id3v1_tag["artist"] = "My Band"
        m.id3v1_tag["tracknum"] = 5
      end

      m = Mp3Info.new(tmp)
      expect(m.id3v1_tag["title"]).to eq("My Song")
      expect(m.id3v1_tag["artist"]).to eq("My Band")
      expect(m.id3v1_tag["tracknum"]).to eq(5)
    end
  end

  describe "#stream" do
    it "provides frame-by-frame iteration" do
      stream = mp3.stream
      expect(stream).to be_a(MPEGStream)

      frame = stream.each_frame.first
      expect(frame.position).to be >= 0
      expect(frame.header).to be_a(MPEGHeader)
      expect(frame.data).to be_a(String)
    end
  end

  describe "#validate" do
    it "returns a validation report" do
      report = mp3.validate
      expect(report).to be_a(StreamValidator::ValidationReport)
      expect(report.frame_count).to be > 0
      expect(report.duration).to be > 0
      expect(report.errors).to be_a(Array)
      expect(report.warnings).to be_a(Array)
    end

    it "report has valid? and to_s" do
      report = mp3.validate
      expect(report.valid?).to be(true).or be(false)
      expect(report.to_s).to include("Validation report")
    end
  end

  describe "#replaygain_info" do
    it "aggregates replay gain from all sources" do
      rg = mp3.replaygain_info
      expect(rg).to be_a(ReplaygainInfo)
      expect(rg.to_s).to be_a(String)
    end
  end
end
