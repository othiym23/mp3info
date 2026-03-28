require "mp3info/binary_conversions"

using Mp3InfoLib::BinaryConversions

describe MPEGStream do
  context "with a sample MP3 file" do
    before :all do
      @mp3_filename = "test_stream.mp3"
      create_sample_mp3_file(@mp3_filename)
    end

    after :all do
      FileUtils.rm_f(@mp3_filename)
    end

    it "iterates over all frames in the file" do
      stream = MPEGStream.new(@mp3_filename)
      frames = stream.each_frame.to_a
      expect(frames).not_to be_empty
      expect(frames.first).to be_a(MPEGStream::FrameInfo)
    end

    it "provides frame position, header, and data for each frame" do
      stream = MPEGStream.new(@mp3_filename)
      frame = stream.each_frame.first
      expect(frame.position).to be >= 0
      expect(frame.header).to be_a(MPEGHeader)
      expect(frame.header.valid?).to be true
      expect(frame.data).not_to be_nil
      expect(frame.data.bytesize).to eq(frame.header.frame_size)
    end

    it "returns an enumerator when called without a block" do
      stream = MPEGStream.new(@mp3_filename)
      enum = stream.each_frame
      expect(enum).to be_a(Enumerator)
    end

    it "provides a frame_count method" do
      stream = MPEGStream.new(@mp3_filename)
      expect(stream.frame_count).to be > 0
    end

    it "provides a frames method for array access" do
      stream = MPEGStream.new(@mp3_filename)
      frames = stream.frames
      expect(frames).to be_a(Array)
      expect(frames.size).to eq(stream.frame_count)
    end
  end

  context "with a real MP3 file with many frames" do
    before :all do
      @path = File.join(__dir__, "../../sample-metadata/Replay Gain RVA2/06-normal-volume.mp3")
    end

    it "iterates over all frames" do
      stream = MPEGStream.new(@path)
      frames = []
      stream.each_frame { |f| frames << f }
      expect(frames.size).to be > 100
      expect(frames.first.header.valid?).to be true
    end

    it "collects MPEG version and layer for all frames" do
      stream = MPEGStream.new(@path)
      versions = Set.new
      layers = Set.new
      sample_rates = Set.new
      stream.each_frame do |frame|
        versions << frame.header.version
        layers << frame.header.layer
        sample_rates << frame.header.sample_rate
      end
      expect(versions).not_to be_empty
      expect(layers).not_to be_empty
      expect(sample_rates).not_to be_empty
    end

    it "calculates duration from frame walking" do
      stream = MPEGStream.new(@path)
      total_duration = 0.0
      stream.each_frame { |f| total_duration += f.header.frame_duration }
      expect(total_duration).to be_within(1).of(7)
    end

    it "skips the ID3v2 tag and does not include it in frame data" do
      stream = MPEGStream.new(@path)
      first_frame = stream.each_frame.first
      expect(first_frame.position).to be > 0
      expect(first_frame.data[0].ord).to eq(0xFF)
      expect(first_frame.data[1].ord & 0xE0).to eq(0xE0)
    end
  end

  context "with a file containing inter-frame gaps" do
    before :all do
      @mp3_filename = "test_gaps.mp3"
      # Build a file with junk between frames
      # Valid MPEG1 Layer III 128kbps 44100Hz stereo: 0xFFFB9064
      valid_header = "\xFF\xFB\x90\x64".b
      frame_size = 417
      frame1 = valid_header + ("\x00" * (frame_size - 4))
      junk = "JUNKDATA".b
      frame2 = valid_header + ("\x00" * (frame_size - 4))

      File.binwrite(@mp3_filename, frame1 + junk + frame2)
    end

    after :all do
      FileUtils.rm_f(@mp3_filename)
    end

    it "finds frames on both sides of the gap" do
      stream = MPEGStream.new(@mp3_filename)
      frames = stream.frames
      expect(frames.size).to eq(2)
      expect(frames[0].position).to eq(0)
      expect(frames[1].position).to eq(417 + 8)  # frame_size + junk size
    end

    it "reports gaps when include_gaps is true" do
      stream = MPEGStream.new(@mp3_filename)
      items = stream.each_frame(include_gaps: true).to_a
      gap = items.find { |i| i.is_a?(MPEGStream::GapInfo) }
      expect(gap).not_to be_nil
      expect(gap.position).to eq(417)
      expect(gap.size).to eq(8)
    end
  end
end
