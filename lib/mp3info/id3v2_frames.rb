require "iconv"

class ID3v2Frame
  attr_reader :type
  attr_accessor :value
  
  def ID3v2Frame.create_frame(type, value)
    klass = ID3V2_4_FRAME_REGISTRY[type]
    
    if klass
      klass.default(value)
    else
      ID3v2TextFrame.default(value.to_s, type)
    end
  end
  
  def ID3v2Frame.create_frame_from_string(type, value)
    klass = ID3V2_4_FRAME_REGISTRY[type]
    
    if klass
      klass.from_s(value)
    else
      ID3v2TextFrame.from_s(value, type)
    end
  end
  
  def initialize(type, value)
    @type = type
    @value = value
  end
  
  def ID3v2Frame.from_s(value, type = 'XXXX')
    ID3v2Frame.new(type, value)
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
end

class ID3v2TextFrame < ID3v2Frame
  attr_accessor :encoding
  
  ENCODING = { :iso => 0, :utf16 => 1, :utf16be => 2, :utf8 => 3 }
  DEFAULT_ENCODING = ENCODING[:utf8]

  def initialize(type, encoding, value)
    super(type, value)
    @encoding = encoding
  end
  
  def ID3v2TextFrame.default(value, type = 'XXXX')
    ID3v2TextFrame.new(type, DEFAULT_ENCODING, value.to_s)
  end

  def ID3v2TextFrame.from_s(value, type = 'XXXX')
    encoding, string = value.unpack("ca*")  # language encoding bit 0 for iso_8859_1, 1 for unicode
    ID3v2TextFrame.new(type, encoding, ID3v2TextFrame.decode_value(encoding, string))
  end
  
  def to_s
    "#{@encoding.chr}#{encode_value(@encoding, @value)}"
  end
  
  def to_s_pretty
    @value
  end
  
  def ==(object)
    object.respond_to?("value") && @value == object.value &&
    object.respond_to?("encoding") && @encoding == object.encoding
  end
  
  protected
  
  def ID3v2TextFrame.decode_value(encoding, value)
    case encoding
    when ENCODING[:iso]
      Iconv.iconv("UTF-8", "ISO-8859-1", value)[0].chomp(0.chr)
    when ENCODING[:utf16]
      Iconv.iconv("UTF-8", "UTF-16", value)[0].chomp(0.chr).chomp(0.chr)
    when ENCODING[:utf16be]
      Iconv.iconv("UTF-8", "UTF-16BE", value)[0].chomp(0.chr).chomp(0.chr)
    when ENCODING[:utf8]
      value.chomp(0.chr)
    else
      raise Exception.new("invalid encoding #{encoding} parsed from tag with value #{value}")
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
end

class TXXXFrame < ID3v2TextFrame
  attr_accessor :description
  
  def initialize(encoding, description, value)
    super('TXXX', encoding, value)
    @description = description
  end
  
  def TXXXFrame.default(value)
    TXXXFrame.new('Mp3Info Comment', value)
  end

  def TXXXFrame.from_s(value)
    encoding, str = value.unpack("ca*")
    descr, entry = split_descr(encoding, str)
    TXXXFrame.new(encoding, descr, entry)
  end
  
  def to_s
    delimiter = @encoding == ENCODING[:utf8] ? "\000\000" : ""
    "#{@encoding.chr}#{encode_value(@encoding, @description || '')}#{delimiter}#{encode_value(@encoding, @value)}"
  end
  
  def to_s_pretty
    prefix = @description && @description != '' ? "(#{@description}) " : nil
    
    (prefix && prefix != '' ? "#{prefix}: " : '') + @value
  end

  def ==(object)
    object.respond_to?("value") && @value == object.value &&
    object.respond_to?("encoding") && @encoding == object.encoding &&
    object.respond_to?("description") && @description == object.description
  end
  
  protected
  
  def TXXXFrame.split_descr(encoding, string)
    # The ID3v2 spec makes life difficult by using nulls as delimiters in a
    # string itself containing two Unicode strings, so code has to match on
    # the byte-order marks to find the delimiter.
    case encoding
    when ENCODING[:iso]
      matches = string.match(/^(([^\000]*)\000)?([^\000]*\000?)/m)
    when ENCODING[:utf16]
      matches = string.match(/^(([\376\377]{2}.*?)\000\000)?([\376\377]{2}.*\000\000)/m)
    when ENCODING[:utf16be]
      matches = string.match(/^((.*?)\000\000)?(.*\000\000)/m)
    when ENCODING[:utf8]
      matches = string.match(/^(([^\000]*\000)\000\000)?([^\000]*\000)/m)
    else
      raise Exception.new("invalid encoding #{encoding} parsed from tag with value #{string}")
    end
    descr = ID3v2TextFrame.decode_value(encoding, matches[2]) if matches
    entry = ID3v2TextFrame.decode_value(encoding, matches[3]) if matches

    descr = '' if descr.nil?
    [descr, entry]
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
  
  def initialize(encoding, mime_type, picture_type, description, picture_data)
    super(encoding, description, picture_data)
    @mime_type = mime_type
    @picture_type = picture_type
    @type = 'APIC'
  end
  
  def APICFrame.default(value)
    APICFrame.new(DEFAULT_ENCODING, "image/jpeg", "\x00", "cover image", value)
  end

  def APICFrame.from_s(value)
    encoding, str = value.unpack("ca*")
    mime_type, picture_type, descr, entry = split_picture_components(encoding, str)
    APICFrame.new(encoding, mime_type, picture_type, descr, entry)
  end
  
  def to_s
    delimiter = @encoding == ENCODING[:utf8] ? "\000\000" : ""
    "#{@encoding.chr}#{@mime_type}\000#{@picture_type}#{encode_value(@encoding, @description || '')}#{delimiter}#{@value}"
  end

  def to_s_pretty
    "Attached Picture (#{@description}) of image type #{@mime_type} and class #{PICTURE_TYPE[@picture_type]}"
  end
  
  def ==(object)
    object.respond_to?("value") && @value == object.value &&
    object.respond_to?("encoding") && @encoding == object.encoding &&
    object.respond_to?("mime_type") && @mime_type == object.mime_type &&
    object.respond_to?("picture_type") && @picture_type == object.picture_type &&
    object.respond_to?("description") && @description == object.description
  end
  
  private
  
  def APICFrame.split_picture_components(encoding, string)
    matches = string.match(/^([^\000]*)\000([\x00-\x14])(.+)/m)
    mime_type = matches[1] if matches
    picture_type = matches[2] if matches
    raw_content = matches[3] if matches

    case encoding
    when ENCODING[:iso]
      cooked_matches = raw_content.match(/^(([^\000]*)\000)(.*)/m)
    when ENCODING[:utf16]
      cooked_matches = raw_content.match(/^(([\376\377]{2}.*?)\000\000)(.*)/m)
    when ENCODING[:utf16be]
      cooked_matches = raw_content.match(/^((.*?)\000\000)(.*)/m)
    when ENCODING[:utf8]
      cooked_matches = raw_content.match(/^(([^\000]*\000)\000\000)(.*)/m)
    else
      raise Exception.new("invalid encoding #{encoding} parsed from tag with value #{string}")
    end
    descr = ID3v2TextFrame.decode_value(encoding, cooked_matches[2]) if cooked_matches
    entry = cooked_matches[3] if cooked_matches

    [mime_type, picture_type, descr, entry]
  end
end

class COMMFrame < TXXXFrame
  attr_accessor :language
  
  def initialize(encoding, language, description, value)
    super(encoding, description, value)
    @type = 'COMM'
    @language = language
  end
  
  def COMMFrame.default(value)
    COMMFrame.new(DEFAULT_ENCODING, 'ENG', 'Mp3Info Comment', value)
  end

  def COMMFrame.from_s(value)
    encoding, lang, str = value.unpack("ca3a*")
    descr, entry = split_descr(encoding, str)
    COMMFrame.new(encoding, lang, descr, entry)
  end

  def to_s
    delimiter = @encoding == ENCODING[:utf8] ? "\000\000" : ""
    str = "#{encode_value(@encoding, @description || '')}#{delimiter}#{encode_value(@encoding, @value)}"
    "#{@encoding.chr}#{@language || 'XXX'}#{str}"
  end

  def to_s_pretty
    prefix =
      (@description && @description != '' ? "(#{@description})" : '') +
      (@language && @language != '' ? "[#{@language}]" : '')
    
    (prefix && prefix != '' ? "#{prefix}: " : '') + "#{@value}"
  end

  def ==(object)
    object.respond_to?("value") && @value == object.value &&
    object.respond_to?("encoding") && @encoding == object.encoding &&
    object.respond_to?("language") && @language == object.language &&
    object.respond_to?("description") && @description == object.description
  end
end

class PRIVFrame < ID3v2Frame
  attr_accessor :owner
  
  def initialize(owner, value)
    super('PRIV', value)
    @owner = owner
  end
  
  def PRIVFrame.default(value)
    PRIVFrame.new('mailto:ogd@aoaioxxysz.net', value)
  end

  def PRIVFrame.from_s(string)
    matches = string.match(/^([^\000]*)\000(.*)/m)
    owner = matches[1] if matches
    value = matches[2] if matches

    PRIVFrame.new(owner, value)
  end
  
  def to_s
    "#{@owner}\000#{@value}"
  end

  def to_s_pretty
    "PRIVATE DATA (from #{@owner}) [#{@value.inspect}]"
  end

  def ==(object)
    object.respond_to?("value") && @value == object.value &&
    object.respond_to?("owner") && @owner == object.owner
  end
end

class TCONFrame < ID3v2TextFrame
  def initialize(encoding, value)
    super('TCON', encoding, value)
  end
  
  def TCONFrame.default(value)
    TCONFrame.new(DEFAULT_ENCODING, value)
  end

  def TCONFrame.from_s(value)
    encoding, string = value.unpack("ca*")  # language encoding bit 0 for iso_8859_1, 1 for unicode
    TCONFrame.new(encoding, ID3v2TextFrame.decode_value(encoding, string))
  end
  
  def genre_code
    reversed = {}
    Mp3Info::GENRES.each_index{ |index| reversed[Mp3Info::GENRES[index]] = index}
    (reversed[@value] || 255).to_s
  end

  def to_s_pretty
    "#{@value} (#{genre_code})"
  end
end

class UFIDFrame < ID3v2Frame
  attr_accessor :namespace
  
  def initialize(namespace, value)
    super('UFID', value)
    @namespace = namespace
  end
  
  def UFIDFrame.default(value)
    UFIDFrame.new('http://www.id3.org/dummy/ufid.html', value)
  end

  def UFIDFrame.from_s(value)
    namespace, unique_id = value.split(0.chr)
    UFIDFrame.new(namespace, unique_id)
  end
  
  def to_s
    "#{@namespace}\000#{@value}"
  end
  
  def to_s_pretty
    "#{@namespace}: #{@value.inspect}"
  end
end

ID3V2_4_FRAME_REGISTRY =
{
   'APIC' => APICFrame,
   'COMM' => COMMFrame,
   'PRIV' => PRIVFrame,
   'TCON' => TCONFrame,
   'TXXX' => TXXXFrame,
   'UFID' => UFIDFrame
}
