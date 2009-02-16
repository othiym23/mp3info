require 'mp3info'

class ReplaygainInfo
  def initialize(mp3info)
    @mp3info = mp3info
  end
  
  def lame_replaygain
    if @mp3info.lame_header
      @mp3info.lame_header.replay_gain
    else
      nil
    end
  end
  
  def mp3_gain
    if @mp3info.lame_header
      @mp3info.lame_header.mp3_gain_db
    else
      nil
    end
  end
  
  def rva2_replaygain
    if @mp3info.has_id3v2_tag?
      @mp3info.id3v2_tag['RVA2']
    else
      nil
    end
  end
  
  def to_s
    lame_out = lame_string
    rva2_out = rva2_string
    
    out_string = ''
    if (lame_out.size > 0) || (rva2_out.size > 0)
      out_string << "MP3 replay gain adjustments:\n\n"
    end
    out_string << lame_string
    out_string << rva2_string
    
    out_string
  end
  
  private
  
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
  
  def ensure_list(value)
    if value.is_a?(Array)
      value
    else
      [value]
    end
  end
end
