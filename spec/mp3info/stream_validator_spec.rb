require "mp3info/binary_conversions"

using Mp3InfoLib::BinaryConversions

describe StreamValidator do
  context "with a valid sample MP3" do
    before :all do
      @mp3_filename = "test_validator.mp3"
      create_sample_mp3_file(@mp3_filename)
    end

    after :all do
      FileUtils.rm_f(@mp3_filename)
    end

    it "produces a validation report" do
      report = StreamValidator.new(@mp3_filename).validate
      expect(report).to be_a(StreamValidator::ValidationReport)
    end

    it "reports the file as valid" do
      report = StreamValidator.new(@mp3_filename).validate
      expect(report.valid?).to be true
    end

    it "counts frames" do
      report = StreamValidator.new(@mp3_filename).validate
      expect(report.frame_count).to be > 0
    end

    it "reports duration" do
      report = StreamValidator.new(@mp3_filename).validate
      expect(report.duration).to be > 0
    end

    it "reports MPEG version and layer" do
      report = StreamValidator.new(@mp3_filename).validate
      expect(report.mpeg_version).not_to be_nil
      expect(report.layer).not_to be_nil
      expect(report.sample_rate).not_to be_nil
    end

    it "reports bitrate information" do
      report = StreamValidator.new(@mp3_filename).validate
      expect(report.avg_bitrate).to be > 0
      expect(report.bitrate_range).to be_a(Array)
      expect(report.bitrate_range.size).to eq(2)
    end

    it "produces a human-readable string" do
      report = StreamValidator.new(@mp3_filename).validate
      str = report.to_s
      expect(str).to include("Validation report")
      expect(str).to include("VALID")
    end
  end

  context "with a file containing inter-frame gaps" do
    before :all do
      @mp3_filename = "test_gaps_validator.mp3"
      valid_header = "\xFF\xFB\x90\x64".b
      frame_size = 417
      frame1 = valid_header + ("\x00" * (frame_size - 4))
      junk = "JUNKJUNKJUNK".b
      frame2 = valid_header + ("\x00" * (frame_size - 4))
      File.binwrite(@mp3_filename, frame1 + junk + frame2)
    end

    after :all do
      FileUtils.rm_f(@mp3_filename)
    end

    it "reports gaps as warnings" do
      report = StreamValidator.new(@mp3_filename).validate
      gap_warnings = report.warnings.select { |w| w.message.include?("non-MPEG data") }
      expect(gap_warnings).not_to be_empty
      expect(gap_warnings.first.message).to include("12 bytes")
    end
  end

  context "with a truncated file" do
    before :all do
      @mp3_filename = "test_truncated.mp3"
      valid_header = "\xFF\xFB\x90\x64".b
      # Write header + less data than the frame_size (417) indicates
      File.binwrite(@mp3_filename, valid_header + ("\x00" * 200))
    end

    after :all do
      FileUtils.rm_f(@mp3_filename)
    end

    it "reports the truncated frame as an error" do
      report = StreamValidator.new(@mp3_filename).validate
      truncation_errors = report.errors.select { |e| e.message.include?("Truncated") }
      expect(truncation_errors).not_to be_empty
    end
  end

  context "with a real MP3 file" do
    before :all do
      @path = File.join(__dir__, "../../sample-metadata/Replay Gain RVA2/06-normal-volume.mp3")
    end

    it "validates a real file with VBR detection" do
      report = StreamValidator.new(@path).validate
      expect(report.frame_count).to be > 100
      expect(report.duration).to be > 5
      expect(report.mpeg_version).to eq(1.0)
      expect(report.layer).to eq(3)
    end
  end

  context "accessible via Mp3Info#validate" do
    before :all do
      @mp3_filename = "test_mp3info_validate.mp3"
      create_sample_mp3_file(@mp3_filename)
    end

    after :all do
      FileUtils.rm_f(@mp3_filename)
    end

    it "returns a validation report from Mp3Info" do
      mp3 = Mp3Info.new(@mp3_filename)
      report = mp3.validate
      expect(report).to be_a(StreamValidator::ValidationReport)
      expect(report.valid?).to be true
    end
  end
end
