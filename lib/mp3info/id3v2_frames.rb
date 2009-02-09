require 'yaml'
require 'iconv'

module ID3V24
  class FrameException < StandardError ; end
  
  class Frame
    attr_reader :type
    attr_reader :raw_size
    attr_accessor :value
    
    def self.create_frame(type, value)
      klass = find_class(type)

      if klass
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
      $stderr.puts("ID3V24.create_frame_from_string(type='#{type}',value=[#{value.inspect}]) =>...") if $DEBUG
      
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
      @raw_size = value.respond_to?(:size) ? value.size : 0
    end
    
    def Frame.default(value, type = 'XXXX')
      Frame.new(type, value)
    end
  
    def Frame.from_s(value, type = 'XXXX')
      Frame.new(type, value)
    end
    
    def to_s
      @value
    end
    
    def to_s_pretty
      @value
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
    DEFAULT_ENCODING = ENCODING[:utf16]
  
    def initialize(type, encoding, value)
      super(type, value)
      @encoding = encoding
    end
    
    def self.default(value, type = 'XXXX')
      TextFrame.new(type, DEFAULT_ENCODING, value.to_s)
    end
  
    def self.from_s(value, type = 'XXXX')
      encoding, string = value.unpack("ca*")  # language encoding bit 0 for iso_8859_1, 1 for unicode
      TextFrame.new(type, encoding, TextFrame.decode_value(encoding, string).tr("\000",''))
    end
    
    def to_s
      @encoding.chr << encode_value(@encoding, @value)
    end
    
    def to_s_pretty
      @value
    end
    
    def ==(object)
      object.respond_to?("value") && @value == object.value &&
      object.respond_to?("encoding") && @encoding == object.encoding
    end
    
    protected
    
    def self.decode_value(encoding, value)
      case encoding
      when ENCODING[:iso]
        Iconv.iconv("UTF-8", "ISO-8859-1", value)[0].chomp("\x00")
      when ENCODING[:utf16]
        Iconv.iconv("UTF-8", "UTF-16", value)[0].chomp("\x00")
      when ENCODING[:utf16be]
        Iconv.iconv("UTF-8", "UTF-16BE", value)[0].chomp("\x00")
      when ENCODING[:utf8]
        value.chomp("\x00")
      else
        raise(FrameException, "invalid encoding #{encoding} encountered in tag value #{value.inspect}")
      end
    end
    
    def encode_value(encoding, value)
      if value
        case encoding
        when ENCODING[:iso]
          Iconv.iconv("ISO-8859-1", "UTF-8", value.to_s)[0] + "\000"
        when ENCODING[:utf16]
          Iconv.iconv("UTF-16", "UTF-8", value.to_s)[0] + "\000\000"
        when ENCODING[:utf16be]
          Iconv.iconv("UTF-16BE", "UTF-8", value.to_s)[0] + "\000\000"
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
      
      $stderr.puts("ID3V24::TextFrame.split_encoded(encoding=#{encoding},string=[#{string.inspect}]) => [prefix='#{prefix.inspect}',remainder=[#{remainder.inspect}]]") if $DEBUG
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
      delimiter = @encoding == ENCODING[:utf8] ? "\000\000" : ""
      @encoding.chr << encode_value(@encoding, @description || '') << delimiter << encode_value(@encoding, @value)
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
      delimiter = @encoding == ENCODING[:utf8] ? "\000\000" : ""
      @encoding.chr << encode_value(@encoding, @description || '') << delimiter << @value
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
      delimiter = @encoding == ENCODING[:utf8] ? "\000\000" : ""
      @encoding.chr << @mime_type << 0.chr << @picture_type << \
        encode_value(@encoding, @description || '') << delimiter << @value
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
      delimiter = @encoding == ENCODING[:utf8] ? "\000\000" : ""
      @encoding.chr << (@language || 'XXX') << encode_value(@encoding, @description || '') << \
        delimiter << encode_value(@encoding, @value)
    end
  
    def to_s_pretty
      prefix =
        (@description && @description != '' ? "(#{@description})" : '') +
        (@language && @language != '' ? "[#{@language}]" : '')
      
      (prefix && prefix != '' ? "#{prefix}: " : '') << "#{@value}"
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
      TCONFrame.new(encoding, TextFrame.decode_value(encoding, TCONFrame.from_genre_code(string)))
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
      hidden_genre = string.match(/\((\d+)\)/)
      if hidden_genre
        ID3::GENRES[hidden_genre[1].to_i]
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
      object.respond_to?("namespace") && @owner == object.namespace
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
      (@encoding.chr << encode_value(@encoding, @value.strftime("%Y-%m-%d"))) if @value
    end
    
    def to_s_pretty
      "Release date: #{@value.to_s}"
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
end