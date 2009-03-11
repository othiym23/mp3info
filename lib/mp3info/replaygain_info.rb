require 'mp3info'

class UserTextReplaygainInfo
  def initialize(id3v2)
    @id3v2 = id3v2
  end
  
  def track_db
    if @id3v2.find_frames_by_description('replaygain_track_gain').size > 0
      @id3v2.find_frames_by_description('replaygain_track_gain').first.value.to_f
    end
  end
  
  def track_peak
    if @id3v2.find_frames_by_description('replaygain_track_peak').size > 0
      @id3v2.find_frames_by_description('replaygain_track_peak').first.value.to_f
    end
  end
  
  def track_minimum
    if track_minmax.size > 0
      track_minmax.first.value.split(',')[0].to_i
    end
  end
  
  def track_maximum
    if track_minmax.size > 0
      track_minmax.first.value.split(',')[1].to_i
    end
  end
  
  def album_db
    if @id3v2.find_frames_by_description('replaygain_album_gain').size > 0
      @id3v2.find_frames_by_description('replaygain_album_gain').first.value.to_f
    end
  end
  
  def album_peak
    if @id3v2.find_frames_by_description('replaygain_album_peak').size > 0
      @id3v2.find_frames_by_description('replaygain_album_peak').first.value.to_f
    end
  end
  
  def album_minimum
    if album_minmax.size > 0
      album_minmax.first.value.split(',')[0].to_i
    end
  end
  
  def album_maximum
    if album_minmax.size > 0
      album_minmax.first.value.split(',')[1].to_i
    end
  end
  
  def mp3gain_undo_string
    if @id3v2.find_frames_by_description('mp3gain_undo').size > 0
      @id3v2.find_frames_by_description('mp3gain_undo').first.value
    end
  end
  
  def valid?
    @id3v2.find_frames_by_description('replaygain_track_gain').size == 1 &&
    @id3v2.find_frames_by_description('replaygain_track_peak').size == 1 &&
    @id3v2.find_frames_by_description('replaygain_album_gain').size == 1 &&
    @id3v2.find_frames_by_description('replaygain_album_peak').size == 1 &&
    @id3v2.find_frames_by_description('mp3gain_minmax').size == 1 &&
    @id3v2.find_frames_by_description('mp3gain_album_minmax').size == 1 &&
    @id3v2.find_frames_by_description('mp3gain_undo').size == 1
  end
  
  private
  
  def track_minmax
    @id3v2.find_frames_by_description('mp3gain_minmax')
  end
  
  def album_minmax
    @id3v2.find_frames_by_description('mp3gain_album_minmax')
  end
end

class SoundCheckInfo
  def initialize(soundcheck_string)
    @raw_soundcheck = soundcheck_string
  end

  def SoundCheckInfo.from_id3v2(id3v2)
    candidates = id3v2.find_frames_by_description('iTunNORM')
    # TODO: find a way of judging the quality of these things
    if candidates && candidates.size > 0
      SoundCheckInfo.new(candidates.first.value)
    else
      nil
    end
  end
  
  def SoundCheckInfo.from_replaygain(gain, peak)
    soundcheck = []
    # left and right channel of 1/1000 dB-milliwatt gain
    soundcheck[0] = soundcheck[1] = db_to_soundcheck(gain, 1000)
    # left and right channel of 1/2500 dB-milliwatt gain
    soundcheck[2] = soundcheck[3] = db_to_soundcheck(gain, 2500)
    # left and right peak volume, 1-32,768 (0-100%) -- seemingly unused
    soundcheck[6] = soundcheck[7] = replaygain_peak_to_soundcheck_peak(peak)
    # nobody outside Apple seems to know what these numbers are for.
    soundcheck[4] = soundcheck[5] = soundcheck[8] = soundcheck[9] = '0000FEEB'
    
    SoundCheckInfo.new(soundcheck.join(' '))
  end

  def to_replaygain
    soundcheck = to_raw_numbers
    raise(Exception, "Invalid Soundcheck format") unless soundcheck.size == 10
    
    high_gain = soundcheck_to_db(soundcheck[0..1].max, 1000)
    low_gain  = soundcheck_to_db(soundcheck[2..3].max, 2500)
    peak      = soundcheck_peak_to_replaygain_peak(soundcheck[6..7].max)
    [high_gain, low_gain, peak]
  end
  
  def to_s
    @raw_soundcheck
  end
  
  def to_frame
    raise(Exception, "Invalid Soundcheck format") unless to_raw_numbers.size == 10
    
    ID3V24::COMMFrame.new(ID3V24::TextFrame::DEFAULT_ENCODING, 'eng', 'iTunNORM', @raw_soundcheck)
  end
  
  def valid?
    valid_raw_value? && valid_gain_value? && valid_peak_value?
  end
  
  def valid_raw_value?
    to_raw_numbers.size == 10
  end
  
  private
  
  def to_raw_numbers
    @raw_soundcheck.split(' ').map { |element| element.hex }
  end
  
  def db_to_soundcheck(gain, base)
    value = ((10.0 ** (-gain.to_f / 10.0)) * base.to_f).round
    value = 65_534 if value > 65_534
    
    "%08X" % value
  end
  
  def soundcheck_to_db(soundcheck, base)
    Math.log10(soundcheck.to_f / base.to_f) * -10
  end
  
  def replaygain_peak_to_soundcheck_peak(peak)
    "%08X" % (peak * 32_768).round
  end
  
  # FIXME: highly suspect
  def soundcheck_peak_to_replaygain_peak(peak)
    peak.to_f / 32_768.to_f
  end
  
  def gain_db
    to_replaygain[0..1].max
  end
  
  def peak
    to_replaygain[2]
  end
  
  def valid_gain_value?
    -60.0 < gain_db && gain_db < 60.0
  end
  
  def valid_peak_value?
    peak > 0
  end
end

class ReplaygainInfo
  def initialize(mp3info)
    @mp3info = mp3info
  end
  
  def lame_replaygain
    @mp3info.lame_header.replay_gain if @mp3info.lame_header
  end
  
  def mp3_gain
    @mp3info.lame_header.mp3_gain_db if @mp3info.lame_header
  end
  
  def rvad_replaygain
    @mp3info.id3v2_tag['RVAD'] if @mp3info.has_id3v2_tag?
  end
  
  def rva2_replaygain
    @mp3info.id3v2_tag['RVA2'] if @mp3info.has_id3v2_tag?
  end
  
  def xrva_replaygain
    @mp3info.id3v2_tag['XRVA'] if @mp3info.has_id3v2_tag?
  end
  
  def xrv_replaygain
    @mp3info.id3v2_tag['XRV'] if @mp3info.has_id3v2_tag?
  end
  
  def itunes_replaygain
    SoundCheckInfo.from_id3v2(@mp3info.id3v2_tag) if @mp3info.has_id3v2_tag?
  end
  
  def foobar_replaygain
    UserTextReplaygainInfo.new(@mp3info.id3v2_tag) if @mp3info.has_id3v2_tag?
  end
  
  def to_s
    lame_out   = lame_string
    rvad_out   = rvad_string
    rva2_out   = rva2_string
    xrva_out   = xrva_string
    xrv_out    = xrv_string
    itunes_out = itunes_string
    foobar_out = foobar_string
    
    out_string = ''
    if (lame_out.size > 0) || (rvad_out.size > 0) || (rva2_out.size > 0) ||
       (xrva_out.size > 0) || (xrv_out.size > 0)  || (itunes_out.size > 0) || (foobar_out.size > 0)
      out_string << "MP3 replay gain adjustments:\n\n"
    end
    out_string << itunes_out
    out_string << lame_out
    out_string << foobar_out
    out_string << rvad_out
    out_string << rva2_out
    out_string << xrva_out
    out_string << xrv_out
    
    out_string
  end
  
  private
  
  def itunes_string
    out_string = ''
    sc = itunes_replaygain
    
    if sc
      high_gain, low_gain, peak = sc.to_replaygain
      
      out_string << "iTunes adjustment (1.0 milliWatt/dBm basis): % #-4.2g dB\n" % high_gain
      out_string << "iTunes adjustment (2.5 milliWatt/dBm basis): % #-4.2g dB\n" % low_gain
      out_string << "iTunes peak volume (should be ~1):           % #6.5g\n"     % peak
      out_string << "\n"
    end
    
    out_string
  end
  
  def lame_string
    out_string = ''
    if lame_replaygain
      out_string << "LAME radio gain:      % #-4.2g dB (#{lame_replaygain.radio.originator})\n" % [lame_replaygain.radio.adjustment] if lame_replaygain.radio.set?
      out_string << "LAME audiophile gain: % #-4.2g dB (#{lame_replaygain.audiophile.originator})\n" % [lame_replaygain.audiophile.adjustment] if lame_replaygain.audiophile.set?
      out_string << "LAME MP3 gain:        % #-4.2g dB\n" % [mp3_gain] if mp3_gain
      out_string << "LAME peak volume:     % #-4.2g dB\n" % [lame_replaygain.db] if lame_replaygain.db
      out_string << "\n"
    end
    
    out_string
  end
  
  def rvad_string
    out_string = ''
    if rvad_replaygain
      ensure_list(rvad_replaygain).each do |rvad|
        out_string << "RVAD adjustment:\n"
        rvad.adjustments.each do |adjustment|
          out_string << "  #{adjustment.channel_type} gain: % #-4.2g dB" % [adjustment.adjustment]
          if adjustment.peak_gain_bit_width > 0
            out_string << " (peak gain limit: #{adjustment.peak_gain})\n"
          end
        end
        out_string << "\n"
      end
    end
    
    out_string
  end
  
  def rva2_string
    out_string = ''
    if rva2_replaygain
      ensure_list(rva2_replaygain).each do |rva2|
        out_string << "RVA2 #{rva2.identifier} adjustment:\n"
        rva2.adjustments.each do |adjustment|
          out_string << "  #{adjustment.channel_type} gain: % #-4.2g dB" % [adjustment.adjustment]
          if adjustment.peak_gain_bit_width > 0
            out_string << " (peak gain limit: #{adjustment.peak_gain})\n"
          end
        end
        out_string << "\n"
      end
    end
    
    out_string
  end
  
  def xrva_string
    out_string = ''
    if xrva_replaygain
      ensure_list(xrva_replaygain).each do |xrva|
        out_string << "XRVA #{xrva.identifier} adjustment:\n"
        xrva.adjustments.each do |adjustment|
          out_string << "  #{adjustment.channel_type} gain: % #-4.2g dB" % [adjustment.adjustment]
          if adjustment.peak_gain_bit_width > 0
            out_string << " (peak gain limit: #{adjustment.peak_gain})\n"
          end
        end
        out_string << "\n"
      end
    end
    
    out_string
  end
  
  def xrv_string
    out_string = ''
    if xrv_replaygain
      ensure_list(xrv_replaygain).each do |xrva|
        out_string << "XRV #{xrv.identifier} adjustment:\n"
        xrv.adjustments.each do |adjustment|
          out_string << "  #{adjustment.channel_type} gain: % #-4.2g dB" % [adjustment.adjustment]
          if adjustment.peak_gain_bit_width > 0
            out_string << " (peak gain limit: #{adjustment.peak_gain})\n"
          end
        end
        out_string << "\n"
      end
    end
    
    out_string
  end
  
  def foobar_string
    out_string = ''
    fb2krg = foobar_replaygain
    
    if fb2krg.valid?
      out_string << "Foobar 2000 track gain: % #-4.2g dB (%#6.4g peak)\n" % [fb2krg.track_db, fb2krg.track_peak]
      out_string << "Foobar 2000 track minimum: #{fb2krg.track_minimum}\n" 
      out_string << "Foobar 2000 track maximum: #{fb2krg.track_maximum}\n"
      out_string << "Foobar 2000 album gain: % #-4.2g dB (%#6.4g peak)\n" % [fb2krg.album_db, fb2krg.album_peak]
      out_string << "Foobar 2000 album minimum: #{fb2krg.album_minimum}\n"
      out_string << "Foobar 2000 album maximum: #{fb2krg.album_maximum}\n"
      out_string << "Foobar 2000 mp3gain undo string: \"#{fb2krg.mp3gain_undo_string}\"\n\n"
    end
    
    out_string
  end
  
  def ensure_list(value)
    if value.is_a?(Array)
      value
    else
      [value]
    end
  end
end
