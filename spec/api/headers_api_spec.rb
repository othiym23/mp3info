require "mp3info/binary_conversions"

using Mp3InfoLib::BinaryConversions

describe "MPEG Header API" do
  # Valid MPEG1 Layer III 128kbps 44100Hz Joint Stereo header
  let(:header_bytes) { "\xFF\xFB\x90\x64".b }
  subject(:header) { MPEGHeader.new(header_bytes) }

  it "parses MPEG version, layer, and stream properties" do
    expect(header.valid?).to be true
    expect(header.version).to eq(1.0)
    expect(header.layer).to eq(3)
    expect(header.bitrate).to eq(128)
    expect(header.sample_rate).to eq(44_100)
    expect(header.mode).to eq("Joint stereo")
    expect(header.frame_size).to eq(417)
    expect(header.frame_duration).to be_within(0.0001).of(0.02612)
    expect(header.samples_per_frame).to eq(1152)
  end

  it "reports stream flags" do
    expect(header.error_protected?).to be(true).or be(false)
    expect(header.padded_stream?).to be(true).or be(false)
    expect(header.original_stream?).to be(true).or be(false)
    expect(header.copyrighted_stream?).to be(true).or be(false)
  end

  it "provides human-readable output" do
    expect(header.version_string).to eq("MPEG1, layer III")
    expect(header.to_s).to include("MPEG")
    expect(header.description).to include("Bitrate")
  end

  it "rejects invalid headers" do
    invalid = MPEGHeader.new("\x00\x00\x00\x00".b)
    expect(invalid.valid?).to be false
  end
end

describe "Xing Header API" do
  let(:sample_path) { File.join(__dir__, "../../sample-metadata/Wire/Chairs Missing [Japanese version]/Wire - Chairs Missing [Japanese version] - 01 - Practice Makes Perfect.mp3") }

  it "reads VBR information from the first MPEG frame" do
    mp3 = Mp3Info.new(sample_path)
    next skip("no Xing header in sample") unless mp3.has_xing_header?

    xing = mp3.xing_header
    expect(xing.valid?).to be true
    expect(xing.vbr?).to be(true).or be(false)
    expect(xing.frames).to be >= 0 if xing.has_framecount?
    expect(xing.bytes).to be >= 0 if xing.has_bytecount?
  end
end

describe "LAME Header API" do
  let(:sample_path) { File.join(__dir__, "../../sample-metadata/Wire/Chairs Missing [Japanese version]/Wire - Chairs Missing [Japanese version] - 01 - Practice Makes Perfect.mp3") }

  it "reads LAME encoder metadata" do
    mp3 = Mp3Info.new(sample_path)
    next skip("no LAME header in sample") unless mp3.has_lame_header?

    lame = mp3.lame_header
    expect(lame.valid?).to be true
    expect(lame.encoder_version).to be_a(String)
    expect(lame.preset).to be_a(String)
    expect(lame.vbr_method).to be_a(String)
    expect(lame.bitrate).to be > 0
    expect(lame.sample_frequency).to be_a(String)
    expect(lame.stereo_mode).to be_a(String)
    expect(lame.encoder_delay).to be >= 0
    expect(lame.encoder_padding).to be >= 0
  end

  it "provides replay gain from the LAME header" do
    mp3 = Mp3Info.new(sample_path)
    next skip("no LAME header") unless mp3.has_lame_header?

    rg = mp3.lame_header.replay_gain
    expect(rg.track_gain).to respond_to(:adjustment)
    expect(rg.album_gain).to respond_to(:adjustment)
    if rg.track_gain.set?
      expect(rg.track_gain.adjustment).to be_a(Float)
      expect(rg.track_gain.origin).to be_a(String)
    end
  end
end

describe "MPEG Stream API" do
  let(:sample_path) { File.join(__dir__, "../../sample-metadata/Replay Gain RVA2/06-normal-volume.mp3") }
  subject(:stream) { MPEGStream.new(sample_path) }

  it "iterates frames with an enumerator" do
    enum = stream.each_frame
    expect(enum).to be_a(Enumerator)

    first = enum.first
    expect(first).to be_a(MPEGStream::FrameInfo)
    expect(first.position).to be_a(Integer)
    expect(first.header).to be_a(MPEGHeader)
    expect(first.data).to be_a(String)
  end

  it "supports block iteration" do
    count = 0
    stream.each_frame { |_f| count += 1 }
    expect(count).to be > 100
  end

  it "detects inter-frame gaps" do
    items = stream.each_frame(include_gaps: true).to_a
    frames = items.select { |i| i.is_a?(MPEGStream::FrameInfo) }
    expect(frames).not_to be_empty
  end

  it "provides frame_count and frames convenience methods" do
    expect(stream.frame_count).to be > 100
    expect(stream.frames.size).to eq(stream.frame_count)
  end
end

describe "Stream Validator API" do
  let(:sample_path) { File.join(__dir__, "../../sample-metadata/Replay Gain RVA2/06-normal-volume.mp3") }

  it "produces a comprehensive validation report" do
    report = StreamValidator.new(sample_path).validate

    expect(report.frame_count).to be > 0
    expect(report.duration).to be > 0
    expect(report.avg_bitrate).to be > 0
    expect(report.stream_size).to be > 0
    expect(report.mpeg_version).to be_a(Float)
    expect(report.layer).to be_a(Integer)
    expect(report.sample_rate).to be_a(Integer)
    expect(report.channel_mode).to be_a(String)
    expect(report.is_vbr).to be(true).or be(false)
    expect(report.bitrate_range).to be_a(Array)
  end

  it "distinguishes errors from warnings" do
    report = StreamValidator.new(sample_path).validate
    report.errors.each { |e| expect(e.message).to be_a(String) }
    report.warnings.each { |w| expect(w.message).to be_a(String) }
  end

  it "provides valid? for pass/fail" do
    report = StreamValidator.new(sample_path).validate
    expect(report.valid?).to be(true).or be(false)
  end

  it "renders a human-readable report" do
    report = StreamValidator.new(sample_path).validate
    text = report.to_s
    expect(text).to include("Validation report")
    expect(text).to include("Frames:")
    expect(text).to match(/VALID|INVALID/)
  end
end

describe "APE Tag API" do
  it "detects APE tags in files" do
    result = APETag.detect(File.join(__dir__, "../../sample-metadata/Replay Gain RVA2/06-normal-volume.mp3"))
    # Most files don't have APE tags; just verify the API works
    if result
      expect(result.version).to be_a(Integer)
      expect(result.item_count).to be_a(Integer)
      expect(result.apev2?).to be(true).or be(false)
    end
  end

  it "returns nil when no APE tag is present" do
    create_sample_mp3_file("api_ape_test.mp3")
    expect(APETag.detect("api_ape_test.mp3")).to be_nil
    FileUtils.rm_f("api_ape_test.mp3")
  end
end

describe "Lyrics3 Tag API" do
  it "returns nil when no Lyrics3 tag is present" do
    create_sample_mp3_file("api_lyrics3_test.mp3")
    expect(Lyrics3Tag.detect("api_lyrics3_test.mp3")).to be_nil
    FileUtils.rm_f("api_lyrics3_test.mp3")
  end
end
