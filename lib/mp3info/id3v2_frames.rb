# encoding: utf-8
require 'yaml'
require 'iconv'
require 'time'
require 'mp3info/compatibility_utils'

module ID3V24
  class FrameException < StandardError ; end
  
  class Frame
    attr_reader :type
    attr_reader :raw_size
    attr_accessor :value
    
    def self.create_frame(type, value)
      klass = find_class(type)
      $stderr.puts("ID3V24::Frame.create_frame(type='#{type}',value=[#{value.inspect}]) => klass=[#{klass}]") if $DEBUG

      if klass
        $stderr.puts("...klass='#{klass}'") if $DEBUG
        klass.default(value)
      else
        # all the 'T###' frames contain encoded text, all the
        # 'W###' frames contain URIs
        case type[0,1]
        when 'T'
          TextFrame.default(value.to_s, type)
        when 'W'
          LinkFrame.default(value, type)
        else
          Frame.default(value, type)
        end
      end
    end
    
    def self.create_frame_from_string(type, value)
      klass = find_class(type)
      $stderr.puts("ID3V24::Frame.create_frame_from_string(type='#{type}',value=[#{value[0..255].inspect}...]) =>...") if $DEBUG
      
      if klass
        $stderr.puts("...klass='#{klass}'") if $DEBUG
        klass.from_s(value)
      else
        # all the 'T###' frames contain encoded text, all the
        # 'W###' frames contain URIs
        case type[0,1]
        when 'T'
          $stderr.puts("...klass='ID3V24::TextFrame'") if $DEBUG
          TextFrame.from_s(value, type)
        when 'W'
          $stderr.puts("...klass='ID3V24::LinkFrame'") if $DEBUG
          LinkFrame.from_s(value, type)
        else
          $stderr.puts("...klass='ID3V24::Frame'") if $DEBUG
          Frame.from_s(value, type)
        end
      end
    end
    
    def initialize(type, value)
      @type = type
      @value = value
      $stderr.puts("...frame value is [#{value.inspect.size > 255 ? "#{value.inspect[0..255]}...\"" : value.inspect}]") if $DEBUG
      @raw_size = value.respond_to?(:size) ? value.size : 0
    end
    
    def Frame.default(value, type = 'XXXX')
      Frame.new(type, value)
    end
  
    def Frame.from_s(value, type = 'XXXX')
      Frame.new(type, value)
    end
    
    def to_s
      @value.to_s
    end
    
    def to_s_pretty
      @value.to_s
    end
    
    def ==(object)
      object.respond_to?("value") && @value == object.value
    end
    
    def frame_info
      frame_ref = YAML::load_file(File.join(File.dirname(__FILE__), 'frame-ref-24.yml'))
      if frame_ref[@type]
        if frame_ref[@type]['long']
          frame_ref[@type]['long']
        else
          frame_ref[@type]['terse']
        end
      else
        "No description available for frame type '#{@type}'."
      end
    end
    
    private
    
    def self.find_class(type)
      begin
        ID3V24.const_get(("#{type.tr("\000",'')}Frame").intern)
      rescue NameError # don't care, cuz we have defaults
      end
    end
  end
  
  class TextFrame < Frame
    attr_accessor :encoding
    
    ENCODING = { :iso => 0, :utf16 => 1, :utf16be => 2, :utf8 => 3 }
    DEFAULT_ENCODING = ENCODING[:utf8]
  
    def initialize(type, encoding, value)
      super(type, value)
      @encoding = encoding
    end
    
    def self.default(value, type = 'XXXX')
      TextFrame.new(type, DEFAULT_ENCODING, value.to_s)
    end
  
    def self.from_s(value, type = 'XXXX')
      if value && value.length > 0
        encoding, string = value.unpack("ca*")  # language encoding bit 0 for iso_8859_1, 1 for unicode
        TextFrame.new(type, encoding, TextFrame.decode_value(encoding, string))
      else
        default('', type)
      end
    end
    
    def to_s
      @encoding.chr << encode_value(@encoding, @value).to_s_ignore_encoding
    end
    
    def to_s_pretty
      @value
    end
    
    def ==(object)
      # we don't care if the encodings don't match. Identity for text frames is defined by the value.
      object.respond_to?("value") && @value == object.value
    end
    
    protected
    
    def self.decode_value(encoding, value)
      case encoding
      when ENCODING[:iso]
        Iconv.iconv("UTF-8", "ISO-8859-1", value).first.strip
      when ENCODING[:utf16]
        Iconv.iconv("UTF-8", "UTF-16", value).first.strip
      when ENCODING[:utf16be]
        Iconv.iconv("UTF-8", "UTF-16BE", value).first.strip
      when ENCODING[:utf8]
        # probably inefficient way to make sure that strings end up in
        # UTF-8 in Ruby 1.9 in a backwards-compatible way
        Iconv.iconv("UTF-8", "UTF-8", value).first.strip
      else
        raise(FrameException, "invalid encoding #{encoding} encountered in tag value #{value.inspect}")
      end
    end
    
    def encode_value(encoding, value)
      if value
        case encoding
        when ENCODING[:iso]
          Iconv.iconv("ISO-8859-1", "UTF-8", value.to_s + "\000").first
        when ENCODING[:utf16]
          Iconv.iconv("UTF-16", "UTF-8",     value.to_s + "\000").first
        when ENCODING[:utf16be]
          Iconv.iconv("UTF-16BE", "UTF-8",   value.to_s + "\000").first
        when ENCODING[:utf8]
          value.to_s + "\000"
        else
          raise Exception.new("invalid encoding #{encoding} parsed from tag with value #{value}")
        end
      end
    end
    
    def self.split_encoded(encoding, string)
      # The ID3v2 spec makes life difficult by using nulls as delimiters in a
      # string itself containing two Unicode strings, so code has to match on
      # the byte-order marks to find the delimiter.
      case encoding
      when ENCODING[:iso], ENCODING[:utf8]
        prefix, remainder = string.split("\x00", 2)
      when ENCODING[:utf16], ENCODING[:utf16be]
        prefix, remainder = string.split(/\x00\x00/, 2);
        if (prefix.size % 2) != 0
          prefix, remainder = string.split(/\x00\x00\x00/, 2)
          prefix += "\x00"
        end
      else
        raise Exception.new("invalid encoding #{encoding} parsed from tag with value #{string}")
      end
      
      $stderr.puts("ID3V24::TextFrame.split_encoded(encoding=#{encoding},string=[#{string[0..255].inspect}...]) => [prefix='#{prefix.inspect}',remainder=[#{remainder[0..255].inspect}...]]") if $DEBUG
      [prefix, remainder]
    end
  end
  
  class LinkFrame < Frame
    def initialize(type, value)
      super(type, value)
    end
    
    def self.default(value, type = 'XXXX')
      LinkFrame.new(type, value.to_s)
    end
  
    def self.from_s(value, type = 'XXXX')
      LinkFrame.new(type, value)
    end
    
    def to_s
      @value
    end
    
    def to_s_pretty
      "URL: " << @value
    end
  end
  
  class TXXXFrame < TextFrame
    attr_accessor :description
    
    def initialize(encoding, description, value)
      super('TXXX', encoding, value)
      @description = description
    end
    
    def self.default(value)
      TXXXFrame.new(DEFAULT_ENCODING, 'Mp3Info Comment', value)
    end
  
    def self.from_s(value)
      encoding, str = value.unpack("ca*")
      descr, entry = split_descr(encoding, str)
      TXXXFrame.new(encoding, descr, entry)
    end
    
    def to_s
      @encoding.chr << encode_value(@encoding, @description || '').to_s_ignore_encoding << encode_value(@encoding, @value || '').to_s_ignore_encoding
    end
    
    def to_s_pretty
      prefix = @description && @description != '' ? "(#{@description}) " : nil
      (prefix && prefix != '' ? "#{prefix}: " : '') << @value
    end
  
    def ==(object)
      object.respond_to?("value") && @value == object.value &&
      object.respond_to?("encoding") && @encoding == object.encoding &&
      object.respond_to?("description") && @description == object.description
    end
    
    protected
    
    def self.split_descr(encoding, string)
      descr, entry = split_encoded(encoding, string)
      [decode_value(encoding, descr), decode_value(encoding, entry)]
    end
  end
  
  class TXXFrame < TXXXFrame
  end
  
  class WXXXFrame < TextFrame
    attr_accessor :description
    
    def initialize(encoding, description, value)
      super('WXXX', encoding, value)
      @description = description
    end
    
    def self.default(value)
      WXXXFrame.new(DEFAULT_ENCODING, 'Mp3Info User Link', value)
    end
  
    def self.from_s(value)
      $stderr.puts("raw value of WXXX frame is #{value.inspect}") if $DEBUG
      encoding, str = value.unpack("ca*")
      $stderr.puts("encoding #{encoding} str #{str.inspect}") if $DEBUG
      descr, entry = split_descr(encoding, str)
      WXXXFrame.new(encoding, descr, entry)
    end
    
    def to_s
      @encoding.chr << encode_value(@encoding, @description || '').to_s_ignore_encoding << @value
    end
    
    def to_s_pretty
      prefix = @description && @description != '' ? "(#{@description}) " : nil
      (prefix && prefix != '' ? "#{prefix}: " : '') << @value
    end
  
    def ==(object)
      object.respond_to?("value") && @value == object.value &&
      object.respond_to?("encoding") && @encoding == object.encoding &&
      object.respond_to?("description") && @description == object.description
    end
    
    protected
    
    def self.split_descr(encoding, string)
      descr, entry = split_encoded(encoding, string)
      [decode_value(encoding, descr), entry]
    end
  end
  
  class APICFrame < TXXXFrame
    attr_accessor :mime_type, :picture_type
    
    PICTURE_TYPE = {  "\x00" =>  "Other",
                      "\x01" =>  "32x32 pixels 'file icon' (PNG only)",
                      "\x02" =>  "Other file icon",
                      "\x03" =>  "Cover (front)",
                      "\x04" =>  "Cover (back)",
                      "\x05" =>  "Leaflet page",
                      "\x06" =>  "Media (e.g. label side of CD)",
                      "\x07" =>  "Lead artist/lead performer/soloist",
                      "\x08" =>  "Artist/performer",
                      "\x09" =>  "Conductor",
                      "\x0A" =>  "Band/Orchestra",
                      "\x0B" =>  "Composer",
                      "\x0C" =>  "Lyricist/text writer",
                      "\x0D" =>  "Recording Location",
                      "\x0E" =>  "During recording",
                      "\x0F" =>  "During performance",
                      "\x10" =>  "Movie/video screen capture",
                      "\x11" =>  "A bright coloured fish",
                      "\x12" =>  "Illustration",
                      "\x13" =>  "Band/artist logotype",
                      "\x14" =>  "Publisher/Studio logotype" }
    
    def initialize(encoding, mime_type, picture_type, description, picture_data, raw_size = 0)
      super(encoding, description, picture_data)
      @raw_size = raw_size if raw_size > 0
      @mime_type = mime_type
      @picture_type = picture_type
      @type = 'APIC'
    end
    
    def self.default(value)
      APICFrame.new(DEFAULT_ENCODING, "image/jpeg", "\x03", "cover image", value)
    end
  
    def self.from_s(value)
      $stderr.puts("APICFrame.from_s(value.size=#{value.size})") if $DEBUG
      encoding, str = value.unpack("ca*")
      mime_type, picture_type, descr, entry = split_picture_components(encoding, str)
      APICFrame.new(encoding, mime_type, picture_type, descr, entry, value.size)
    end
    
    def APICFrame.picture_type_to_name(type)
      PICTURE_TYPE[type]
    end
    
    def APICFrame.name_to_picture_type(name)
      PICTURE_TYPE.invert[name]
    end
    
    def to_s
      @encoding.chr << @mime_type << 0.chr << @picture_type << \
        encode_value(@encoding, @description || '').to_s_ignore_encoding << @value
    end
    
    def picture_type_name
      APICFrame.picture_type_to_name(@picture_type)
    end
  
    def picture_type_name=(name)
      @picture_type = APICFrame.name_to_picture_type(name)
    end
  
    def to_s_pretty
      about = 'Attached Picture'
      about << ' (' << @description << ')' if @description && '' != @description
      about << ' of image type ' << @mime_type
      about << ' and class ' <<  PICTURE_TYPE[@picture_type]
      about << ' of size ' << @value.size.to_s
      
      about
    end
    
    def ==(object)
      object.respond_to?("value") && @value == object.value &&
      object.respond_to?("encoding") && @encoding == object.encoding &&
      object.respond_to?("mime_type") && @mime_type == object.mime_type &&
      object.respond_to?("picture_type") && @picture_type == object.picture_type &&
      object.respond_to?("description") && @description == object.description
    end
    
    protected
    
    def self.split_picture_components(encoding, string)
      mime_type, remainder = string.split("\x00", 2)
      picture_type, raw_content = remainder.unpack("aa*")
      descr, entry = split_encoded(encoding, raw_content)
      
      [mime_type, picture_type, TextFrame.decode_value(encoding, descr), entry]
    end
  end
  
  class PICFrame < APICFrame
    protected
    
    def self.split_picture_components(encoding, string)
      mime_type, picture_type, raw_content = string.unpack("3aaa*")
      descr, entry = split_encoded(encoding, raw_content)
      
      [mime_type, picture_type, TextFrame.decode_value(encoding, descr), entry]
    end
    
    def self.mimify(image_type)
      case image_type
      when 'GIF'
        'image/gif'
      when 'PNG'
        'image/png'
      when 'JPG'
        'image/jpeg'
      else
        'application/binary'
      end
    end
  end
  
  class COMMFrame < TXXXFrame
    attr_accessor :language
    
    def initialize(encoding, language, description, value)
      super(encoding, description, value)
      @type = 'COMM'
      @language = language
    end
    
    def self.default(value)
      COMMFrame.new(DEFAULT_ENCODING, 'eng', 'Mp3Info Comment', value)
    end
  
    def self.from_s(value)
      encoding, lang, raw_content = value.unpack("ca3a*")
      descr, entry = split_descr(encoding, raw_content)
      $stderr.puts("ID3V24::COMMFrame.from_s(value=[#{value.inspect}]) => [encoding=#{encoding}, lang=[#{lang}], descr=[#{descr}], entry=[#{entry}]]") if $DEBUG
      COMMFrame.new(encoding, lang, descr, entry)
    end
  
    def to_s
      $stderr.puts("COMMFrame.to_s => [#{encoding}|#{@language || 'XXX'}|#{encode_value(@encoding, @description || '').inspect}|#{encode_value(@encoding, @value).inspect}]") if $DEBUG
      @encoding.chr << (@language || 'XXX') << encode_value(@encoding, @description || '').to_s_ignore_encoding << encode_value(@encoding, @value || '').to_s_ignore_encoding
    end
  
    def to_s_pretty
      prefix =
        (@description && @description != '' ? "(#{@description})" : '') +
        (@language && @language != '' ? "[#{@language}]" : '')
      
      $stderr.puts("COMMFrame.to_s_pretty => [#{prefix}|#{@value}]") if $DEBUG
      "#{prefix && prefix != '' ? "#{prefix}: " : ''}#{@value}"
    end
  
    def ==(object)
      object.respond_to?("value") && @value == object.value &&
      object.respond_to?("encoding") && @encoding == object.encoding &&
      object.respond_to?("language") && @language == object.language &&
      object.respond_to?("description") && @description == object.description
    end
  end
  
  class COMFrame < COMMFrame
  end
  
  class PRIVFrame < Frame
    attr_accessor :owner
    
    def initialize(owner, value)
      super('PRIV', value)
      @owner = owner
    end
    
    def self.default(value)
      PRIVFrame.new('mailto:ogd@aoaioxxysz.net', value)
    end
  
    def self.from_s(string)
      owner, value = string.split("\x00", 2)
  
      PRIVFrame.new(owner, value)
    end
    
    def to_s
      '' << @owner << 0.chr << @value
    end
  
    def to_s_pretty
      "PRIVATE DATA (from #{@owner}) [#{@value.inspect}]"
    end
  
    def ==(object)
      object.respond_to?("value") && @value == object.value &&
      object.respond_to?("owner") && @owner == object.owner
    end
  end
  
  class TCMPFrame < TextFrame
    def initialize(encoding, value)
      super('TCMP', encoding, value)
    end
    
    def self.default(value)
      TCMPFrame.new(ENCODING[:iso], value)
    end
  
    def self.from_s(value)
      encoding, string = value.unpack("ca*")
      TCMPFrame.new(encoding, string == "1" ? true : false)
    end
    
    def to_s
      @encoding.chr << (@value ? "1" : "0")
    end
  
    def to_s_pretty
      "This track is #{value ? "" : "not "}part of a compilation."
    end
  end
  
  class TCONFrame < TextFrame
    def initialize(encoding, value)
      super('TCON', encoding, TCONFrame.from_genre_code(value))
    end
    
    def self.default(value)
      TCONFrame.new(DEFAULT_ENCODING, TCONFrame.from_genre_code(value))
    end
  
    def self.from_s(value)
      encoding, string = value.unpack("ca*")
      TCONFrame.new(encoding, TCONFrame.from_genre_code(TextFrame.decode_value(encoding, string)))
    end
    
    def genre_code
      reversed = {}
      ID3::GENRES.each_index{ |index| reversed[ID3::GENRES[index]] = index}
      reversed[@value] || 255
    end
  
    def to_s_pretty
      "#{@value} (#{genre_code})"
    end
    
    def TCONFrame.from_genre_code(string)
      if hidden_genre = string.match(/\((\d+)\)/)
        ID3::GENRES[hidden_genre[1].to_i]
      elsif bare_genre = string.match(/\A(\d+)\Z/)
        ID3::GENRES[bare_genre[1].to_i] || string
      else
        string
      end
    end
  end
  
  class TCOFrame < TCONFrame
  end
  
  class UFIDFrame < Frame
    attr_accessor :namespace
    
    def initialize(namespace, value)
      super('UFID', value)
      @namespace = namespace
    end
    
    def self.default(value)
      UFIDFrame.new('http://www.id3.org/dummy/ufid.html', value)
    end
  
    def self.from_s(value)
      namespace, unique_id = value.split(0.chr)
      UFIDFrame.new(namespace, unique_id)
    end
    
    def to_s
      '' << @namespace << 0.chr << @value
    end
    
    def to_s_pretty
      "#{@namespace}: #{@value.inspect}"
    end
  
    def ==(object)
      object.respond_to?("value") && @value == object.value &&
      object.respond_to?("namespace") && @namespace == object.namespace
    end
  end
  
  class UFIFrame < UFIDFrame
    def initialize(namespace, value)
      super(namespace, value)
      @namespace = namespace
    end
  end
  
  class XDORFrame < TextFrame
    def initialize(encoding, value)
      super('XDOR', encoding, value)
    end
    
    def self.default(value)
      XDORFrame.new(DEFAULT_ENCODING, value)
    end
  
    def self.from_s(value)
      encoding, string = value.unpack("ca*")
      string = decode_value(encoding, string)
      
      date_elems = string.match(/(\d{4})(-(\d{2})-(\d{2}))?/)
      if date_elems
        date = Time.gm(date_elems[1], date_elems[3], date_elems[4])
      end
  
      XDORFrame.new(encoding, date)
    end
    
    def to_s
      (@encoding.chr << encode_value(@encoding, @value.strftime("%Y-%m-%d")).to_s_ignore_encoding) if @value
    end
    
    def to_s_pretty
      "Release date: #{@value.rfc2822}"
    end
  end
  
  class XSOPFrame < TextFrame
    def initialize(encoding, value)
      super('XSOP', encoding, value)
    end
    
    def self.default(value)
      XSOPFrame.new(DEFAULT_ENCODING, value)
    end
  
    def self.from_s(value)
      encoding, string = value.unpack("ca*")
      XSOPFrame.new(encoding, TextFrame.decode_value(encoding, string))
    end
  end
  
  class RVA2ParseError < StandardError ; end
  
  class RVA2Adjustment
    # as per http://www.id3.org/id3v2.4.0-frames, section 4.11
    CHANNEL_TYPE = {
      0x00 => 'Other',
      0x01 => 'Master volume',
      0x02 => 'Front right',
      0x03 => 'Front left',
      0x04 => 'Back right',
      0x05 => 'Back left',
      0x06 => 'Front centre',
      0x07 => 'Back centre',
      0x08 => 'Subwoofer'
    }
    
    attr_accessor :channel_code
    attr_accessor :raw_adjustment
    
    def initialize(channel_code, raw_adjustment, peak_gain_width, peak_gain_bits = [])
      @channel_code = channel_code
      @raw_adjustment = raw_adjustment
      @peak_gain_width = peak_gain_width
      @peak_gain_bits = peak_gain_bits
    end
    
    def channel_type
      CHANNEL_TYPE[@channel_code] || 'Unknown'
    end
    
    def adjustment
      @raw_adjustment.to_f / 512.0
    end
    
    def adjustment=(new_adjustment)
      @raw_adjustment = (new_adjustment * 512).to_i
    end
    
    def peak_gain
      @peak_gain_bits
    end
    
    def peak_gain_bit_width
      @peak_gain_width
    end
    
    def to_bin
      "#{@channel_code.chr}#{encode_raw_adjustment}#{encode_peak_gain_bits}"
    end
    
    private
    
    def encode_raw_adjustment
      [@raw_adjustment >> 8, @raw_adjustment & 0xff].pack("cC")
    end
    
    def encode_peak_gain_bits
      "#{@peak_gain_width.chr}#{@peak_gain_bits.to_binary_string}"
    end
  end
  
  class RVA2Frame < Frame
    attr_accessor :identifier
    
    def initialize(id, adjustments = [])
      super('RVA2', adjustments)
      @identifier = id
    end
    
    def self.default(value)
      default_adjustment = RVA2Adjustment.new(0x01, 0, 0)
      default_adjustment.adjustment = value
      RVA2Frame.new('track', [default_adjustment])
    end
    
    def self.from_s(value)
      id, raw_adjustment_list = value.split("\x00", 2)
      $stderr.puts("RVA2Frame.from_s(value=#{value.inspect}) => id=[#{id.inspect}] raw_adjustment_list=[#{raw_adjustment_list.inspect}]") if $DEBUG
      RVA2Frame.new(id, parse_adjustments(raw_adjustment_list))
    end
    
    def adjustments
      @value
    end
    
    def to_s
      "#{@identifier}\x00#{encode_adjustments}"
    end
    
    private
    
    def self.parse_adjustments(raw_value)
      adjustment_list = []
      total_bytes = raw_value.safe_length
      cur_pos = 0
      $stderr.puts("RVA2Frame.parse_adjustments(raw_value=#{raw_value.inspect}) => total_bytes=[#{total_bytes}]") if $DEBUG
      
      while total_bytes - cur_pos > 0 do
        # get the channel code byte
        raise(RVA2ParseError, "insufficient bytes left to parse out another adjustment") if cur_pos + 1 >= total_bytes;
        channel_code = raw_value[cur_pos].to_ordinal
        cur_pos += 1
        $stderr.puts("RVA2Frame.parse_adjustments channel_code=[#{channel_code.inspect}] cur_pos=[#{cur_pos}]") if $DEBUG
        
        # get the 16-bit signed big-endian value for the gain adjustment
        raise(RVA2ParseError, "insufficient bytes left to parse out another adjustment") if cur_pos + 2 >= total_bytes;
        adjustment = decode_gain_value(raw_value.slice(cur_pos, 2))
        cur_pos += 2
        $stderr.puts("RVA2Frame.parse_adjustments adjustment=[#{adjustment.inspect}] cur_pos=[#{cur_pos}]") if $DEBUG
        
        # figure out how many bits' worth of peak gain scale adjustment there is
        raise(RVA2ParseError, "insufficient bytes left to parse out another adjustment") if cur_pos + 1 > total_bytes;
        peak_gain_bit_size = raw_value[cur_pos].to_ordinal
        cur_pos += 1
        $stderr.puts("RVA2Frame.parse_adjustments peak_gain_bit_size=[#{peak_gain_bit_size.inspect}] cur_pos=[#{cur_pos}]") if $DEBUG
        
        peak_gain_value = 0
        # ...and then fetch them if they're there
        if peak_gain_bit_size > 0
          peak_gain_byte_width = ((peak_gain_bit_size - 1) / 8) + 1
          peak_gain_bytes = raw_value.slice(cur_pos, peak_gain_byte_width)
          peak_gain_value = peak_gain_bytes.to_binary_array[-peak_gain_bit_size..-1].to_binary_decimal
          cur_pos += peak_gain_byte_width
          $stderr.puts("RVA2Frame.parse_adjustments peak_gain_bytes=[#{peak_gain_bytes.inspect}] peak_gain_value=[#{peak_gain_value}] cur_pos=[#{cur_pos}]") if $DEBUG
        end
        
        adjustment_list << RVA2Adjustment.new(channel_code, adjustment, peak_gain_bit_size, peak_gain_value)
      end
      
      adjustment_list
    end
    
    def self.decode_gain_value(binary_string)
      binary_string.unpack("cC*").inject(0) { |res, b| (res << 8) | b } 
    end
    
    def encode_adjustments
      bin_string = ''
      @value.each do |adjustment|
        bin_string << adjustment.to_bin
      end
      
      bin_string
    end
  end
  
  # 2.3 compatibility frame created by normalize; identical to RVA2
  # TODO: move to ID3V23::Frame when splitting apart 2.2/3/4 frames.
  # normalize: http://normalize.nongnu.org/
  class XRVAFrame < RVA2Frame
    def initialize(identifier, adjustments = [])
      super(identifier, adjustments)
      @type = 'XRVA'
    end
    
    def self.default(value)
      default_adjustment = RVA2Adjustment.new(0x01, 0, 0)
      default_adjustment.adjustment = value
      XRVAFrame.new('track', [default_adjustment])
    end
    
    def self.from_s(value)
      id, raw_adjustment_list = value.split("\x00", 2)
      $stderr.puts("XRVAFrame.from_s(value=#{value.inspect}) => id=[#{id.inspect}] raw_adjustment_list=[#{raw_adjustment_list.inspect}]") if $DEBUG
      XRVAFrame.new(id, parse_adjustments(raw_adjustment_list))
    end
  end
  
  # 2.2 compatibility frame created by normalize (?); identical to RVA2
  # TODO: move to ID3V22::Frame when splitting apart 2.2/3/4 frames.
  # normalize: http://normalize.nongnu.org/
  class XRVFrame < RVA2Frame
    def initialize(identifier, adjustments = [])
      super(identifier, adjustments)
      @type = 'XRV'
    end
    
    def self.default(value)
      default_adjustment = RVA2Adjustment.new(0x01, 0, 0)
      default_adjustment.adjustment = value
      XRVFrame.new('track', [default_adjustment])
    end
    
    def self.from_s(value)
      id, raw_adjustment_list = value.split("\x00", 2)
      $stderr.puts("XRVFrame.from_s(value=#{value.inspect}) => id=[#{id.inspect}] raw_adjustment_list=[#{raw_adjustment_list.inspect}]") if $DEBUG
      XRVFrame.new(id, parse_adjustments(raw_adjustment_list))
    end
  end
  
  # 2.2 legacy replaygain frame type. A simplified version of the totally
  # insane RVAD frame, below.
  class RVAFrame < Frame
    RIGHT  = 0x01
    LEFT   = 0x02
    
    CHANNELS     = [RIGHT, LEFT]
    
    TO_RVA2_TYPE = {
      RIGHT => 0x02,
      LEFT  => 0x03
    }
    
    def initialize(raw_string)
      super('RVA', raw_string)
    end
    
    def self.default(value)
      frame = RVAFrame.new(default_raw_string)
      frame.set_db(RIGHT, value)
      frame.set_db(LEFT, value)
      frame
    end
    
    def self.from_s(raw_string)
      RVAFrame.new(raw_string)
    end
    
    def bit_width
      @value[1].to_ordinal
    end
    
    def set_raw(channel, value)
      @value[channel_to_offset(channel), byte_width] = value.abs.to_binary_array(bit_width).to_binary_string
    end
    
    def get_raw(channel)
      @value[channel_to_offset(channel), byte_width].to_binary_decimal.to_binary_array(bit_width).to_binary_decimal
    end
    
    def set_db(channel, value)
      set_channel_sign!(channel, value) 
      set_raw(channel, db_to_value(value.abs, channel))
    end
    
    def get_db(channel)
      value_to_db(get_raw(channel), channel)
    end
    
    # get the "default" right channel gain in dB for this adjustment
    def right_gain
      get_db(RIGHT)
    end
    
    def right_gain=(value)
      set_db(RIGHT, value)
    end
    
    # get the "default" left channel gain in dB for this adjustment
    def left_gain
      get_db(LEFT)
    end
    
    def left_gain=(value)
      set_db(LEFT, value)
    end
    
    # It's unclear to me how the peak values are meant to be interpreted:
    # the logical interpretation would be the absolute peak value for the
    # specified channel over the duration of the stream, where the maximum
    # is 2 ** bit_width - 1, but I lack enough data in practice to say with
    # confidence that's how this field is used in the wild.
    def get_peak(channel)
      @value[channel_to_offset(channel) + peak_offset(channel), byte_width].to_binary_decimal
    end
    
    def set_peak(channel, value)
      @value[channel_to_offset(channel) + peak_offset(channel), byte_width] = value.to_binary_string
    end
    
    def right_peak
      get_peak(RIGHT)
    end
    
    def right_peak=(value)
      set_peak(RIGHT, value)
    end
    
    def left_peak
      get_peak(LEFT)
    end
    
    def left_peak=(value)
      set_peak(LEFT, value)
    end
    
    def adjustments
      adjustment_list = []
      CHANNELS.each do |channel|
        adjustment_list << RVA2Adjustment.new(TO_RVA2_TYPE[channel], (get_db(channel) * 512).round, bit_width, get_peak(channel))
      end
      
      adjustment_list
    end
    
    def set_channel_sign!(channel, value)
      @value[0] = ((value < 0) ? (bit_field & ~channel) : (bit_field | channel)).chr
    end
    
    private
    
    def byte_width
      (@value[1].to_ordinal.to_f / 8).ceil
    end
    
    def bit_field
      @value[0].to_ordinal
    end
    
    def channel_to_offset(channel)
      # base offset is 1 increment / decrement field byte + 1 bitwidth byte
      base_offset = 2
      
      case channel
      when RIGHT
        base_offset
      when LEFT
        base_offset + byte_width
      end
    end
    
    def peak_offset(channel)
      2 * byte_width
    end
    
    def self.default_raw_string
      string = ''
      # 1 byte indicating that the front right and front left channels are adjusted
      # positively
      string << (RIGHT | LEFT).chr
      # 1 byte indicating the width of the field in which we're storing adjustments
      string << 16.chr
      # 0.0 dB adjustment for both of the front channels by default
      string << "\x00\x00\x00\x00"
      # peak values of 0 for both of the default channels (better safe than sorry)
      string << "\x00\x00\x00\x00"
      
      string
    end
    
    def db_to_value(db, channel)
      [((2 ** bit_width) * ((10 ** ((decrement?(channel, bit_field) ? -1 : 1) * db.abs.to_f / 20.to_f)) - 1.0)).round, (2 ** bit_width) - 1].min
    end

    def value_to_db(value, channel)
      20 * Math.log10(1.0  + ((decrement?(channel, bit_field) ? -1 : 1) * [value.abs, (2 ** bit_width) - 1].min) / (2 ** bit_width).to_f)
    end
    
    def decrement?(channel, bit_field)
      (bit_field & channel) == 0
    end
  end
  
  # Another 2.3 replaygain frame type, this one with an even more demented
  # structure. At least RVA2 sort of makes sense.
  class RVADFrame < Frame
    FRONT_RIGHT  = 0x01
    FRONT_LEFT   = 0x02
    REAR_RIGHT   = 0x04
    REAR_LEFT    = 0x08
    CENTER       = 0x10
    SUBWOOFER    = 0x20
    
    CHANNELS     = [FRONT_RIGHT, FRONT_LEFT, REAR_RIGHT, REAR_LEFT, CENTER, SUBWOOFER]
    
    TO_RVA2_TYPE = {
      FRONT_RIGHT => 0x02,
      FRONT_LEFT  => 0x03,
      REAR_RIGHT  => 0x04,
      REAR_LEFT   => 0x05,
      CENTER      => 0x06,
      SUBWOOFER   => 0x08
    }
    
    def initialize(raw_string)
      super('RVAD', raw_string)
    end
    
    def self.default(value)
      frame = RVADFrame.new(default_raw_string)
      frame.set_db(FRONT_RIGHT, value)
      frame.set_db(FRONT_LEFT, value)
      frame
    end
    
    def self.from_s(raw_string)
      RVADFrame.new(raw_string)
    end
    
    def channel_adjusted?(channel)
      total_size(channel) <= @value.size
    end
    
    def bit_width
      @value[1].to_ordinal
    end
    
    def set_raw(channel, value)
      ensure_capacity!(channel)
      @value[channel_to_offset(channel), byte_width] = value.abs.to_binary_array(bit_width).to_binary_string
    end
    
    def get_raw(channel)
      @value[channel_to_offset(channel), byte_width].to_binary_decimal.to_binary_array(bit_width).to_binary_decimal
    end
    
    def set_db(channel, value)
      set_channel_sign!(channel, value) 
      set_raw(channel, db_to_value(value.abs, channel))
    end
    
    def get_db(channel)
      value_to_db(get_raw(channel), channel)
    end
    
    # get the "default" right channel gain in dB for this adjustment
    def right_gain
      get_db(FRONT_RIGHT)
    end
    
    def right_gain=(value)
      set_db(FRONT_RIGHT, value)
    end
    
    # get the "default" left channel gain in dB for this adjustment
    def left_gain
      get_db(FRONT_LEFT)
    end
    
    def left_gain=(value)
      set_db(FRONT_LEFT, value)
    end
    
    # It's unclear to me how the peak values are meant to be interpreted:
    # the logical interpretation would be the absolute peak value for the
    # specified channel over the duration of the stream, where the maximum
    # is 2 ** bit_width - 1, but I lack enough data in practice to say with
    # confidence that's how this field is used in the wild.
    def get_peak(channel)
      @value[channel_to_offset(channel) + peak_offset(channel), byte_width].to_binary_decimal
    end
    
    def set_peak(channel, value)
      ensure_capacity!(channel)
      @value[channel_to_offset(channel) + peak_offset(channel), byte_width] = value.to_binary_string
    end
    
    def right_peak
      get_peak(FRONT_RIGHT)
    end
    
    def right_peak=(value)
      set_peak(FRONT_RIGHT, value)
    end
    
    def left_peak
      get_peak(FRONT_LEFT)
    end
    
    def left_peak=(value)
      set_peak(FRONT_LEFT, value)
    end
    
    def adjustments
      adjustment_list = []
      CHANNELS.each do |channel|
        if channel_adjusted?(channel)
          adjustment_list << RVA2Adjustment.new(TO_RVA2_TYPE[channel], (get_db(channel) * 512).round, bit_width, get_peak(channel))
        end
      end
      
      adjustment_list
    end
    
    def set_channel_sign!(channel, value)
      @value[0] = ((value < 0) ? (bit_field & ~channel) : (bit_field | channel)).chr
    end
    
    private
    
    def byte_width
      (@value[1].to_ordinal.to_f / 8).ceil
    end
    
    def bit_field
      @value[0].to_ordinal
    end
    
    def ensure_capacity!(channel)
      # dynamically grow the size of the frame, if necessary
      @value << ("\x00" * (total_size(channel) - @value.size)) if @value.size < total_size(channel)
    end
    
    def channel_to_offset(channel)
      # base offset is 1 increment / decrement field byte + 1 bitwidth byte
      base_offset = 2
      
      case channel
      when FRONT_RIGHT
        base_offset
      when FRONT_LEFT
        base_offset + byte_width
      when REAR_RIGHT
        base_offset + 4 * byte_width
      when REAR_LEFT
        base_offset + 5 * byte_width
      when CENTER
        base_offset + 8 * byte_width
      when SUBWOOFER
        base_offset + 10 * byte_width
      end
    end
    
    def total_size(channel)
      # Base offset of 2 bytes for the increment / decrement field and the
      # bit width for gain and peak fields, plus a variable number of bytes
      # for the gain and peak adjustments.
      base_offset = 2
      
      case channel
      when FRONT_RIGHT, FRONT_LEFT
        base_offset +  4 * byte_width
      when REAR_RIGHT, REAR_LEFT
        base_offset +  8 * byte_width
      when CENTER
        base_offset + 10 * byte_width
      when SUBWOOFER
        base_offset + 12 * byte_width
      end
    end
    
    def peak_offset(channel)
      case channel
      when FRONT_RIGHT, FRONT_LEFT, REAR_RIGHT, REAR_LEFT
        2 * byte_width
      when CENTER, SUBWOOFER
        byte_width
      end
    end
    
    def self.default_raw_string
      string = ''
      # 1 byte indicating that the front right and front left channels are adjusted
      # positively
      string << (FRONT_RIGHT | FRONT_LEFT).chr
      # 1 byte indicating the width of the field in which we're storing adjustments
      string << 16.chr
      # 0.0 dB adjustment for both of the front channels by default
      string << "\x00\x00\x00\x00"
      # peak values of 0 for both of the default channels (better safe than sorry)
      string << "\x00\x00\x00\x00"
      
      string
    end
    
    def db_to_value(db, channel)
      [((2 ** bit_width) * ((10 ** ((decrement?(channel, bit_field) ? -1 : 1) * db.abs.to_f / 20.to_f)) - 1.0)).round, (2 ** bit_width) - 1].min
    end

    def value_to_db(value, channel)
      20 * Math.log10(1.0  + ((decrement?(channel, bit_field) ? -1 : 1) * [value.abs, (2 ** bit_width) - 1].min) / (2 ** bit_width).to_f)
    end
    
    def decrement?(channel, bit_field)
      (bit_field & channel) == 0
    end
  end
  
  class RGADAdjustment
    ORIGIN_UNSPECIFIED = 0x0
    ORIGIN_PRESET      = 0x1
    ORIGIN_USER        = 0x2
    ORIGIN_AUTOMATIC   = 0x3
    
    TYPE_UNSET         = 0x0
    TYPE_RADIO         = 0x1
    TYPE_AUDIOPHILE    = 0x2
    
    def initialize(raw_string)
      @raw_string = raw_string
    end
    
    def set?
      raw_adjustment != 0
    end
    
    def type
      case type_code
      when TYPE_UNSET
        'unset'
      when TYPE_RADIO
        'track'
      when TYPE_AUDIOPHILE
        'album'
      end
    end
    
    def origin
      case origin_code
      when ORIGIN_UNSPECIFIED
        'unspecified'
      when ORIGIN_PRESET
        'preset'
      when ORIGIN_USER
        'user'
      when ORIGIN_AUTOMATIC
        'automatic'
      else
        'other'
      end
    end
    
    def adjustment
      raw_adjustment.to_f / 10.0
    end
    
    def adjustment=(value)
      self.raw_adjustment = (value * 10).round
    end
    
    def valid? 
      (TYPE_RADIO == type_code ||
       TYPE_AUDIOPHILE == type_code) &&
      ORIGIN_UNSPECIFIED != origin_code
    end
    
    def negative?
      @raw_string.to_binary_array[6] == 1
    end
    
    def type_code
      @raw_string.to_binary_array[0, 3].to_binary_decimal
    end
    
    def type_code=(value)
      # strip out the old type code
      cleared   = @raw_string[0].to_ordinal & ~(0x7 << 5)
      # ensure the new value doesn't overflow 3 bits and shift into position
      new_value = (value & 0x7) << 5
      # combine the two and store
      @raw_string[0] = (cleared | new_value).chr
    end
    
    def origin_code
      @raw_string.to_binary_array[3, 3].to_binary_decimal
    end
    
    def origin_code=(value)
      # strip out the old origin code
      cleared   = @raw_string[0].to_ordinal & ~(0x7 << 2)
      # ensure the new value doesn't overflow 3 bits and shift into position
      new_value = (value & 0x7) << 2
      # combine the two and store
      @raw_string[0] = (cleared | new_value).chr
    end
    
    def raw_adjustment
      adj = @raw_string.to_binary_array[7, 9].to_binary_decimal
      (negative? ? -adj : adj)
    end
    
    def raw_adjustment=(value)
      $stderr.puts("ID3V24::RGADFrame.raw_adjustment= value #{value} raw_string #{@raw_string.inspect}") if $DEBUG
      new_value = @raw_string.to_binary_array
      new_value[6] = ((0 > value) ? 1 : 0)
      new_value[7, 9] = [value.abs, 2 ** 10 - 1].min.to_binary_array(9)
      $stderr.puts("ID3V24::RGADFrame.raw_adjustment= new_value #{new_value.to_binary_string.inspect}") if $DEBUG
      @raw_string = new_value.to_binary_string
    end
    
    def to_bin
      @raw_string
    end
  end
  
  # http://replaygain.hydrogenaudio.org/file_format_id3v2.html
  class RGADFrame < Frame
    def initialize(raw_string)
      super('RGAD', raw_string)
    end
    
    def self.default(value)
      frame = RGADFrame.new(default_raw_string)
      frame.track_gain = value
      frame.album_gain = value
      frame
    end
    
    def self.from_s(raw_string)
      RGADFrame.new(raw_string)
    end
    
    def track_gain
      RGADAdjustment.new(@value[4, 2])
    end
    
    # This is a little roundabout, but it allows users to directly set the
    # gain in dB, as well as going low-level and manipulating the adjustment
    # representation if necessary.
    def track_gain=(value)
      case
      when value.is_a?(Numeric)
        new_gain = track_gain
        new_gain.adjustment = value
        @value[4, 2] = new_gain.to_bin
      when value.is_a?(RGADAdjustment)
        @value[4, 2] = value.to_bin
      else
        raise(ArgumentError,"track gain doesn't recognize #{value.inspect}")
      end
    end
    
    def album_gain
      RGADAdjustment.new(@value[6, 2])
    end
    
    # This is a little roundabout, but it allows users to directly set the
    # gain in dB, as well as going low-level and manipulating the adjustment
    # representation if necessary.
    def album_gain=(value)
      case
      when value.is_a?(Numeric)
        new_gain = album_gain
        new_gain.adjustment = value
        @value[6, 2] = new_gain.to_bin
      when value.is_a?(RGADAdjustment)
        @value[6, 2] = value.to_bin
      else
        raise(ArgumentError,"album gain doesn't recognize #{value.inspect}")
      end
    end
    
    # For some reason, the Replaygain team decided to use single-precision
    # IEEE 754 floats instead of a sane, fixed-point format. Accordingly, this
    # call will not work if run on systems using non-IEEE 754-compatible
    # floating-point hardware, due to Ruby's reliance on machine implementations.
    def peak
      @value[0, 4].unpack("F").first
    end
    
    def peak=(value)
      @value[0, 4] = [value.to_f].pack("F")
    end
    
    def valid?
      track_gain.valid? &&
      album_gain.valid? &&
      track_gain.type == 'track' &&
      album_gain.type == 'album'
    end
    
    private
    
    def self.default_raw_string
      string = ''
      # 0.0 peak amplitude
      string << "\x00\x00\x00\x00"
      # 0 dB track replay gain adjustment, set automatically
      string << "\x2c\x00"
      # 0 dB album replay gain adjustment, set automatically
      string << "\x4c\x00"
      
      string
    end
  end
end