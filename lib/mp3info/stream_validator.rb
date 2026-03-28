# encoding: binary

require_relative "mpeg_stream"
require_relative "binary_conversions"
require_relative "size_units"

using Mp3InfoLib::BinaryConversions
using Mp3InfoLib::SizeUnits

# Validates an MPEG audio stream by walking every frame and collecting
# statistics, warnings, and errors.
class StreamValidator
  # Complete validation report
  ValidationReport = Struct.new(
    :filename,
    :frame_count,
    :duration,             # total duration in seconds
    :avg_bitrate,          # average bitrate in kbps
    :stream_size,          # total audio bytes
    :mpeg_version,         # dominant MPEG version (Float)
    :layer,                # dominant layer (Integer)
    :sample_rate,          # dominant sample rate (Integer)
    :channel_mode,         # dominant channel mode (String)
    :is_vbr,               # true if bitrates vary
    :bitrate_range,        # [min, max] bitrates
    :xing_frame_count,     # frame count from Xing header, if present
    :errors,               # Array of Error structs
    :warnings,             # Array of Warning structs
    keyword_init: true
  ) do
    def valid?
      errors.empty?
    end

    def to_s
      lines = []
      lines << "Validation report for #{File.basename(filename)}"
      lines << "-" * 72
      lines << "Frames: #{frame_count}  Duration: #{format_duration}  Avg bitrate: #{avg_bitrate}kbps"
      lines << "MPEG#{format_version}, layer #{MPEGHeader::LAYER_STRINGS[layer]}  #{sample_rate / 1000.0}kHz  #{channel_mode}"
      lines << "VBR: #{is_vbr ? "yes (#{bitrate_range[0]}-#{bitrate_range[1]}kbps)" : "no"}"
      lines << "Stream size: #{stream_size.octet_units}"

      if xing_frame_count && xing_frame_count != frame_count
        lines << "Xing frame count: #{xing_frame_count} (actual: #{frame_count})"
      end

      if errors.any?
        lines << ""
        lines << "ERRORS (#{errors.size}):"
        errors.each { |e| lines << "  #{e}" }
      end

      if warnings.any?
        lines << ""
        lines << "WARNINGS (#{warnings.size}):"
        warnings.each { |w| lines << "  #{w}" }
      end

      lines << "" if errors.empty? && warnings.empty?
      lines << "Result: #{valid? ? "VALID" : "INVALID"}"
      lines.join("\n")
    end

    private

    def format_duration
      total = duration.round
      minutes = total / 60
      seconds = total % 60
      "%d:%02d" % [minutes, seconds]
    end

    def format_version
      "%g" % mpeg_version
    end
  end

  Error = Struct.new(:position, :message, keyword_init: true) do
    def to_s
      if position
        "[%#08x] %s" % [position, message]
      else
        message
      end
    end
  end

  Warning = Struct.new(:position, :message, keyword_init: true) do
    def to_s
      if position
        "[%#08x] %s" % [position, message]
      else
        message
      end
    end
  end

  def initialize(filename)
    @filename = filename
    @stream = MPEGStream.new(filename)
  end

  def validate
    errors = []
    warnings = []

    frame_count = 0
    total_duration = 0.0
    total_bytes = 0
    bitrates = []
    versions = Hash.new(0)
    layers = Hash.new(0)
    sample_rates = Hash.new(0)
    modes = Hash.new(0)
    last_frame_pos = nil
    last_frame_size = nil
    crc_failures = 0

    @stream.each_frame(include_gaps: true) do |item|
      if item.is_a?(MPEGStream::GapInfo)
        if item.size > 0
          warnings << Warning.new(
            position: item.position,
            message: "#{item.size} bytes of non-MPEG data between frames"
          )
        end
        next
      end

      frame = item
      frame_count += 1
      total_duration += frame.header.frame_duration
      total_bytes += frame.data.bytesize
      bitrates << frame.header.bitrate

      versions[frame.header.version] += 1
      layers[frame.header.layer] += 1
      sample_rates[frame.header.sample_rate] += 1
      modes[frame.header.mode] += 1

      # Check for truncated frame
      if frame.data.bytesize < frame.header.frame_size
        errors << Error.new(
          position: frame.position,
          message: "Truncated frame: expected #{frame.header.frame_size} bytes, got #{frame.data.bytesize}"
        )
      end

      # CRC validation for error-protected frames
      if frame.header.error_protected? && frame.crc
        computed = compute_crc16(frame)
        if computed && computed != frame.crc
          crc_failures += 1
          errors << Error.new(
            position: frame.position,
            message: "CRC-16 mismatch: expected %04X, computed %04X" % [frame.crc, computed]
          )
        end
      end

      last_frame_pos = frame.position
      last_frame_size = frame.header.frame_size
    end

    if frame_count == 0
      errors << Error.new(position: nil, message: "No MPEG frames found")
      return build_empty_report(errors, warnings)
    end

    # Check version/layer/sample rate consistency
    dominant_version = versions.max_by { |_, v| v }[0]
    dominant_layer = layers.max_by { |_, v| v }[0]
    dominant_sample_rate = sample_rates.max_by { |_, v| v }[0]
    dominant_mode = modes.max_by { |_, v| v }[0]

    if versions.size > 1
      others = versions.reject { |k, _| k == dominant_version }
      others.each do |ver, count|
        warnings << Warning.new(
          position: nil,
          message: "#{count} frames have MPEG version #{ver} (expected #{dominant_version})"
        )
      end
    end

    if layers.size > 1
      others = layers.reject { |k, _| k == dominant_layer }
      others.each do |layer, count|
        warnings << Warning.new(
          position: nil,
          message: "#{count} frames have layer #{layer} (expected #{dominant_layer})"
        )
      end
    end

    if sample_rates.size > 1
      others = sample_rates.reject { |k, _| k == dominant_sample_rate }
      others.each do |sr, count|
        warnings << Warning.new(
          position: nil,
          message: "#{count} frames have sample rate #{sr}Hz (expected #{dominant_sample_rate}Hz)"
        )
      end
    end

    # Check Xing frame count if available
    xing_count = nil
    begin
      mp3 = Mp3Info.new(@filename)
      if mp3.has_xing_header? && mp3.xing_header.has_framecount?
        xing_count = mp3.xing_header.frames
        if xing_count != frame_count
          warnings << Warning.new(
            position: nil,
            message: "Xing header declares #{xing_count} frames, actual count is #{frame_count}"
          )
        end
      end

      if mp3.has_vbri_header?
        warnings << Warning.new(
          position: nil,
          message: "VBRI header present: #{mp3.vbri_header}"
        )
      end

      if mp3.has_ape_tag?
        warnings << Warning.new(
          position: nil,
          message: "APE tag present: #{mp3.ape_tag}"
        )
      end

      if mp3.has_lyrics3_tag?
        warnings << Warning.new(
          position: nil,
          message: "Lyrics3 tag present: #{mp3.lyrics3_tag}"
        )
      end

      # ID3v2 structural validation
      if mp3.has_id3v2_tag?
        validate_id3v2(mp3.id3v2_tag, warnings, errors)
      end
    rescue
      # Can't read mp3info — skip metadata checks
    end

    is_vbr = bitrates.uniq.size > 1
    avg_bitrate = if total_duration > 0
      ((total_bytes * 8) / (total_duration * 1000)).round
    else
      0
    end

    if crc_failures > 0
      warnings << Warning.new(
        position: nil,
        message: "#{crc_failures} of #{frame_count} frames failed CRC-16 validation"
      )
    end

    # Detect trailing non-MPEG data after the last frame
    if last_frame_pos && last_frame_size
      last_frame_end = last_frame_pos + last_frame_size
      # Determine where non-audio data starts at the end of the file
      file_size = File.size(@filename)
      audio_end = file_size
      if file_size >= 128
        data = File.binread(@filename, 128, [file_size - 128, 0].max)
      end
      audio_end -= 128 if data && data[0, 3] == "TAG"

      # Account for APE and Lyrics3 tags
      begin
        ape = APETag.detect(@filename)
        if ape
          ape_size = ape.tag_size + (ape.has_header? ? 32 : 0)
          audio_end = [audio_end - ape_size, 0].max
        end
        lyrics = Lyrics3Tag.detect(@filename)
        audio_end = [audio_end - lyrics.size, 0].max if lyrics
      rescue
        # ignore detection errors
      end

      if last_frame_end < audio_end
        trailing_bytes = audio_end - last_frame_end
        if trailing_bytes > 0
          warnings << Warning.new(
            position: last_frame_end,
            message: "#{trailing_bytes} bytes of non-MPEG data after the last frame"
          )
        end
      end
    end

    ValidationReport.new(
      filename: @filename,
      frame_count: frame_count,
      duration: total_duration,
      avg_bitrate: avg_bitrate,
      stream_size: total_bytes,
      mpeg_version: dominant_version,
      layer: dominant_layer,
      sample_rate: dominant_sample_rate,
      channel_mode: dominant_mode,
      is_vbr: is_vbr,
      bitrate_range: [bitrates.min, bitrates.max],
      xing_frame_count: xing_count,
      errors: errors,
      warnings: warnings
    )
  end

  private

  def build_empty_report(errors, warnings)
    ValidationReport.new(
      filename: @filename,
      frame_count: 0,
      duration: 0.0,
      avg_bitrate: 0,
      stream_size: 0,
      mpeg_version: nil,
      layer: nil,
      sample_rate: nil,
      channel_mode: nil,
      is_vbr: false,
      bitrate_range: [0, 0],
      xing_frame_count: nil,
      errors: errors,
      warnings: warnings
    )
  end

  def validate_id3v2(tag, warnings, errors)
    # 1. Detect duplicate frames that should be unique per spec
    unique_frames = %w[
      TALB TBPM TCOM TCON TCOP TDAT TDLY TENC TEXT TFLT TIT1 TIT2 TIT3 TKEY
      TLAN TLEN TMED TOAL TOFN TOLY TOPE TOWN TPE1 TPE2 TPE3 TPE4 TPOS TPUB
      TRCK TRDA TRSN TRSO TSIZ TSRC TSSE TYER TDRC TDOR TDRL TDTG TSOT TSOP TSOA
    ]
    unique_frames.each do |frame_id|
      frames = tag.frames(frame_id)
      if frames && frames.size > 1
        warnings << Warning.new(
          position: nil,
          message: "Frame #{frame_id} appears #{frames.size} times but should be unique"
        )
      end
    end

    # 2. APIC MIME type vs image magic bytes validation
    apic_frames = tag.frames("APIC")
    apic_frames&.each_with_index do |frame, i|
      next unless frame.respond_to?(:mime_type) && frame.respond_to?(:value)
      detected_mime = detect_image_mime(frame.value)
      if detected_mime && frame.mime_type != detected_mime
        warnings << Warning.new(
          position: nil,
          message: "APIC frame #{i + 1}: declared MIME '#{frame.mime_type}' but data looks like '#{detected_mime}'"
        )
      end
    end

    # 3. Check for empty text frames
    tag.each do |frame_id, _value|
      frames = tag.frames(frame_id)
      next unless frames
      frames.each do |frame|
        if frame.respond_to?(:value) && frame.value.is_a?(String) && frame.value.strip.empty?
          warnings << Warning.new(
            position: nil,
            message: "Frame #{frame_id} has empty value"
          )
        end
      end
    end
  end

  MIME_MAGIC = {
    "\xFF\xD8\xFF".b => "image/jpeg",
    "\x89PNG".b => "image/png",
    "GIF8".b => "image/gif",
    "BM".b => "image/bmp",
    "RIFF".b => "image/webp" # WebP starts with RIFF....WEBP but RIFF is enough to flag mismatch
  }.freeze

  def detect_image_mime(data)
    return nil unless data && data.bytesize >= 4
    MIME_MAGIC.each do |magic, mime|
      return mime if data[0, magic.bytesize] == magic
    end
    nil
  end

  # Compute CRC-16 for an error-protected frame.
  # The CRC covers the last 2 bytes of the header (after sync+version+layer+protection)
  # plus the side information.
  def compute_crc16(frame)
    return nil if frame.data.bytesize < 6

    # CRC-16 polynomial: x^16 + x^15 + x^2 + 1 (0x8005)
    crc = 0xFFFF
    # CRC covers header bytes 2-3 (after the sync word and protection bit)
    # plus the side information
    header_bytes = frame.data[2, 2]  # bytes 2 and 3 of header
    side_info_size = frame.header.side_info_size
    side_info = frame.data[6, side_info_size]  # after 4-byte header + 2-byte CRC

    return nil unless side_info && side_info.bytesize == side_info_size

    data_to_crc = header_bytes + side_info
    data_to_crc.each_byte do |byte|
      8.times do
        bit = (crc & 0x8000) ^ ((byte & 0x80) << 8)
        crc = (crc << 1) & 0xFFFF
        crc ^= 0x8005 if bit != 0
        byte = (byte << 1) & 0xFF
      end
    end

    crc
  end
end
