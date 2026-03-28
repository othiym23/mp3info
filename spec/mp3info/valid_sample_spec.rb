$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe Mp3Info, "when loading a sample MP3 file" do
  include Mp3InfoHelper

  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end

  after do
    FileUtils.rm_f(@mp3_filename)
  end

  it "should load a valid MP3 file without errors" do
    expect { Mp3Info.new(@mp3_filename).close }.not_to raise_error
  end

  it "should successfully provide an Mp3Info object when opening a valid MP3 file" do
    Mp3Info.open(@mp3_filename) { |info| expect(info).to be_a(Mp3Info) }
  end

  it "should return a string description when opening a valid MP3 file" do
    Mp3Info.open(@mp3_filename) { |info| expect(info.to_s).to be_a(String) }
  end

  it "should detect that the sample file contains MPEG 1 audio" do
    Mp3Info.open(@mp3_filename) { |info| expect(info.has_mpeg_header?).to be true ; expect(info.mpeg_header.version).to eq(1) }
  end

  it "should detect that the sample file contains layer 3 audio" do
    Mp3Info.open(@mp3_filename) { |info| expect(info.has_mpeg_header?).to be true ; expect(info.mpeg_header.layer).to eq(3) }
  end

  it "should detect that the sample file does not contain VBR-encoded audio" do
    Mp3Info.open(@mp3_filename) { |info| expect(info.vbr?).not_to be true }
  end

  it "should detect that the sample file has a CBR bitrate of 128kbps" do
    Mp3Info.open(@mp3_filename) { |info| expect(info.bitrate).to eq(128) }
  end

  it "should detect that the sample file is encoded as joint stereo" do
    Mp3Info.open(@mp3_filename) { |info| expect(info.has_mpeg_header?).to be true ; expect(info.mpeg_header.mode).to eq("Joint stereo") }
  end

  it "should detect that the sample file has a sample rate of 44.1kHz" do
    Mp3Info.open(@mp3_filename) { |info| expect(info.has_mpeg_header?).to be true ; expect(info.mpeg_header.sample_rate).to eq(44_100) }
  end

  it "should detect that the sample file is not error-protected" do
    Mp3Info.open(@mp3_filename) { |info| expect(info.has_mpeg_header?).to be true ; expect(info.mpeg_header.error_protected?).to be false }
  end

  it "should detect that the sample file has a duration of 0.1305625 seconds" do
    Mp3Info.open(@mp3_filename) { |info| expect(info.length).to eq(0.1305625) }
  end

  it "should correctly format the summary info for the sample file" do
    Mp3Info.open(@mp3_filename) { |info| expect(info.to_s).to eq("Time: 0:00        MPEG1, layer III          [ 128kbps @ 44.1kHz - Joint stereo ]") }
  end
end
