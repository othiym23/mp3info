class Mp3Info 
  module HashKeys #:nodoc: :deprecated:
    ### lets you specify hash["key"] as hash.key
    ### this came from CodingInRuby on RubyGarden
    ### http://wiki.rubygarden.org/Ruby/page/show/RubyIdioms
    def method_missing(meth,*args)
      m = meth.id2name
      if /=$/ =~ m
        if args.length < 2
          self[m.chop] = args[0]
        else
          # is there any way to get here without a direct message send?
          self[m.chop] = args
        end
      else
        self[m]
      end
    end
  end

  module NumericBits #:nodoc:
    ### returns the selected bit range (b, a) as a number
    ### NOTE: b > a  if not, returns 0
    def bits(b, a)
      t = 0
      b.downto(a) { |i| t += t + self[i] }
      t
    end
  end

  module Mp3FileMethods #:nodoc:
    def get32bits
      size_string = read(4)
      $stderr.printf("DEBUG: 32-bit size 0x%02x%02x%02x%02x\n", size_string[0], size_string[1], size_string[2], size_string[3]) if $DEBUG
      binary_array_to_binary_decimal(byte_str_to_binary_array(size_string,8))
    end

    def get_syncsafe
      size_string = read(4)
      $stderr.printf("DEBUG: syncsafe size 0x%02x%02x%02x%02x\n", size_string[0], size_string[1], size_string[2], size_string[3]) if $DEBUG
      unless (size_string.unpack('V').first & 0x80808080) > 1
        binary_array_to_binary_decimal(byte_str_to_binary_array(size_string,7))
      else
        binary_array_to_binary_decimal(byte_str_to_binary_array(size_string,8))
      end
    end
    
    private
    
    # convert a string representing an array of big-endian bytes into an array of bits
    def byte_str_to_binary_array(src, word_size = 8)
      if (word_size < 1 or word_size > 8)
        raise ArgumentError, word_size.to_s + ' is not a valid word size.'
      end

      binary_array = [];

      src.each_byte do |byte|
        bits = [];
        word_size.downto(1) { |bit| bits << byte[bit - 1] }

        binary_array += bits
      end

      binary_array
    end
    
    # encode a binary array of big-endian bytes into a decimal value
    def binary_array_to_binary_decimal(array)
      decimal = 0

      binary_list = array.reverse

      binary_list.each_with_index do |bit,index|
        raise ArgumentError, "Array must contain only '1' or '0', not '#{bit}'" unless bit == 0 || bit == 1
        decimal += bit << index
      end

      decimal
    end
  end
end
