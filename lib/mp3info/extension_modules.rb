class Mp3Info 
  module HashKeys #:nodoc:
    ### lets you specify hash["key"] as hash.key
    ### this came from CodingInRuby on RubyGarden
    ### http://www.rubygarden.org/ruby?CodingInRuby
    def method_missing(meth,*args)
      m = meth.id2name
      if /=$/ =~ m
        if args.length < 2
          if args[0].is_a? ID3v2Frame
            self[m.chop] = args[0]
          else
            self[m.chop] = ID3v2Frame.create_frame(m.chop, args[0].to_s)
          end
        else
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
      (getc << 24) + (getc << 16) + (getc << 8) + getc
    end
    def get_syncsafe
      (getc << 21) + (getc << 14) + (getc << 7) + getc
    end
  end

end

