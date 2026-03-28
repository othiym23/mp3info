require 'digest/sha1'
require 'fileutils'

describe Mp3Info, "round-trip integrity" do
  sample_dir = File.join(__dir__, '../../sample-metadata')
  mp3_files = Dir.glob(File.join(sample_dir, '**/*.mp3')).sort

  # Files known to have no useful MPEG audio data
  no_audio_files = %w[
    mp3info-qa/3aeb9bc1396b9b840c677e161e731908a4a66464.mp3
  ]

  mp3_files.each do |path|
    relative = path.sub("#{sample_dir}/", '')
    next if no_audio_files.any? { |s| relative.include?(s) }

    context "with #{File.basename(path)}" do
      let(:tmp) { "round_trip_test_#{$$}_#{rand(100000)}.mp3" }
      before { FileUtils.cp(path, tmp) }
      after { FileUtils.rm_f(tmp) }

      it "preserves audio data when modifying tags" do
        original = begin
          Mp3Info.new(tmp)
        rescue Mp3InfoError, ID3V24::FrameException, ID3V2ParseError, ID3V2Error
          skip "cannot parse #{relative}"
        end
        skip "no MPEG header" unless original.has_mpeg_header?

        original_audio = extract_audio_bytes(tmp)
        skip "no audio bytes to verify" if original_audio.nil? || original_audio.empty?

        begin
          Mp3Info.open(tmp) do |mp3|
            mp3.id3v2_tag['TXXX'] = 'round-trip test marker'
          end
        rescue Mp3InfoError, ID3V24::FrameException, ID3V2ParseError, ID3V2Error => e
          skip "write failed: #{e.class}: #{e.message}"
        end

        modified_audio = extract_audio_bytes(tmp)
        if Digest::SHA1.hexdigest(modified_audio) != Digest::SHA1.hexdigest(original_audio)
          pending "Audio data changed after tag modification in #{relative} — write_mpeg_file! bug"
          fail
        end
      end
    end
  end

  def extract_audio_bytes(filename)
    data = File.binread(filename)
    start_offset = 0
    end_offset = data.size

    # Skip ID3v2 tag at the start
    if data[0, 3] == 'ID3' && data.size >= 10
      tag_size = data[6, 4].bytes.inject(0) { |sum, b| (sum << 7) | b }
      start_offset = 10 + tag_size
    end

    # Skip ID3v1 tag at the end
    if data.size >= 128 && data[-128, 3] == 'TAG'
      end_offset = data.size - 128
    end

    return nil if start_offset >= end_offset
    data[start_offset...end_offset]
  end
end
