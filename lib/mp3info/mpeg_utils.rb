#
# Initially ported from eyeD3 by Ryan Finne & Travis Shirk.
#
class String
  # convert a string representing an array of big-endian bytes into an array of bits
  def to_binary_array(size = 8)
    if (size < 1 or size > 8)
      raise ArgumentError, size.to_s + ' is not a valid word size.'
    end
    
    binary_array = [];

    self.each_byte do |byte|
      bits = [];
      size.downto(1) { |bit| bits << byte[bit - 1] }
      
      binary_array += bits
    end
    
    binary_array
  end
  
  # convert a string representing an array of big-endian bytes into its arbitrarily wide Fixnum value
  def to_binary_decimal
    to_binary_array.to_binary_decimal
  end
  
  def from_synchsafe_string
    # At first, second and third glance this is an incredible hack,
    # but mixing and matching ID3v2.4 and non-syncsafe lengths is very common,
    # including previous builds of this library. Easier to patch it here
    # than have to special-case it everywhere else.
    unless (to_binary_decimal & 0x80808080) > 1
      to_binary_array(7).to_binary_decimal
    else
      to_binary_decimal
    end
  end
end

class Array
  # encode a binary array of big-endian bytes back into a string
  def to_binary_string
    binary_string = ''

    binary_list = self.reverse

    chunks = binary_list.size / 8
    chunks += 1 if (binary_list.size % 8 > 0)

    chunks.times do |cur_slice|
      byte = 0

      binary_list[8 * cur_slice, 8].each_with_index do |bit,index|
        raise ArgumentError, "Array must contain only '1' or '0', not '#{bit}'" unless bit == 0 || bit == 1
        byte |= bit << index
      end

      binary_string += byte.chr
    end

    binary_string.reverse
  end
  
  # encode a binary array of big-endian bytes into a decimal value
  def to_binary_decimal
    decimal = 0

    binary_list = self.reverse

    binary_list.each_with_index do |bit,index|
      raise ArgumentError, "Array must contain only '1' or '0', not '#{bit}'" unless bit == 0 || bit == 1
      decimal += bit << index
    end

    decimal
  end
end

class Fixnum
  # encode a decimal into a binary array
  def to_binary_array(padding = 0)
    raise ArgumentError, "Only positive numbers can be translated" if self < 0
    raise ArgumentError, "Padding value must be positive" if padding < 0
    
    binary_array = []
    
    raw_value = self
    while raw_value > 0 do
      binary_array << (raw_value & 1)
      raw_value >>= 1
    end

    ([ 0 ] * ((padding - binary_array.size) > 0 ? padding - binary_array.size : 0)) + binary_array.reverse
  end
  
  # encode a decimal back into a string
  def to_binary_string(padding = 0)
    to_binary_array(padding).to_binary_string
  end
  
  def to_synchsafe_string
    raise ArgumentError, "Only positive numbers can be translated" if self < 0
    raise ArgumentError, "Synchsafe value must be less than 2^28 - 1" if self > 268435455
    
    binary_string = ''
    
    binary_string += ((self >> 21) & 0x7f).chr
    binary_string += ((self >> 14) & 0x7f).chr
    binary_string += ((self >>  7) & 0x7f).chr
    binary_string += ((self >>  0) & 0x7f).chr
    
    binary_string
  end
end

class Bignum
  # encode a decimal into a binary array
  def to_binary_array(padding = 0)
    raise ArgumentError, "Only positive numbers can be translated" if self < 0
    raise ArgumentError, "Padding value must be positive" if padding < 0
    
    binary_array = []
    
    raw_value = self
    while raw_value > 0 do
      binary_array << (raw_value & 1)
      raw_value >>= 1
    end

    ([ 0 ] * ((padding - binary_array.size) > 0 ? padding - binary_array.size : 0)) + binary_array.reverse
  end
  
  # encode a decimal back into a string
  def to_binary_string(padding = 0)
    to_binary_array(padding).to_binary_string
  end
end
