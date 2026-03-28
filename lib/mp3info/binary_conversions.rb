# encoding: binary

# Refinements for binary data conversion used throughout mp3info.
# Use `using Mp3InfoLib::BinaryConversions` in files that need these methods.
module Mp3InfoLib
  module BinaryConversions
    refine String do
      def to_binary_array(size = 8)
        if size < 1 || size > 8
          raise ArgumentError, "#{size} is not a valid word size."
        end

        binary_array = []
        each_byte do |byte|
          bits = []
          size.downto(1) { |bit| bits << byte[bit - 1] }
          binary_array += bits
        end
        binary_array
      end

      def to_binary_decimal
        to_binary_array.to_binary_decimal
      end

      def from_synchsafe_string
        to_binary_array(7).to_binary_decimal
      end

      def synchsafe?
        size == 4 && (to_binary_decimal & 0x80808080) == 0
      end
    end

    refine Array do
      def to_binary_string
        binary_string = ""
        binary_list = reverse
        chunks = binary_list.size / 8
        chunks += 1 if binary_list.size % 8 > 0

        chunks.times do |cur_slice|
          byte = 0
          binary_list[8 * cur_slice, 8].each_with_index do |bit, index|
            raise ArgumentError, "Array must contain only '1' or '0', not '#{bit}'" unless bit == 0 || bit == 1
            byte |= bit << index
          end
          binary_string << byte.chr(Encoding::BINARY)
        end
        binary_string.reverse
      end

      def to_binary_decimal
        decimal = 0
        binary_list = reverse
        binary_list.each_with_index do |bit, index|
          raise ArgumentError, "Array must contain only '1' or '0', not '#{bit}'" unless bit == 0 || bit == 1
          decimal += bit << index
        end
        decimal
      end
    end

    refine Integer do
      def to_binary_array(padding = 0)
        raise ArgumentError, "Only positive numbers can be translated" if self < 0
        raise ArgumentError, "Padding value must be positive" if padding < 0

        binary_array = []
        raw_value = self
        while raw_value > 0
          binary_array << (raw_value & 1)
          raw_value >>= 1
        end
        ([0] * [(padding - binary_array.size), 0].max) + binary_array.reverse
      end

      def to_binary_string(padding = 0)
        to_binary_array(padding).to_binary_string
      end

      def to_synchsafe_string
        raise ArgumentError, "Only positive numbers can be translated" if self < 0
        raise ArgumentError, "Synchsafe value must be less than 2^28 - 1" if self > 268435455

        [(self >> 21) & 0x7f, (self >> 14) & 0x7f, (self >> 7) & 0x7f, self & 0x7f].pack("C4")
      end
    end
  end
end
