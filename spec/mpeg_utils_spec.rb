# encoding: binary
$:.unshift("lib/")

require 'mp3info/mpeg_utils'

module MPEGUtils
  describe String, "when decoding strings into binary arrays" do
    it "should decode the empty string into the empty array" do
      expect(''.to_binary_array).to eq([])
    end

    it "should decode '0' into [0, 0, 1, 1, 0, 0, 0, 0]" do
      eyeD3_version = [ 0, 0, 1, 1, 0, 0, 0, 0 ]
      expect('0'.to_binary_array).to eq(eyeD3_version)
    end

    it "should decode 'COMM' properly" do
      eyeD3_version = [ 0, 1, 0, 0, 0, 0, 1, 1,
                        0, 1, 0, 0, 1, 1, 1, 1,
                        0, 1, 0, 0, 1, 1, 0, 1,
                        0, 1, 0, 0, 1, 1, 0, 1 ]
      expect('COMM'.to_binary_array).to eq(eyeD3_version)
    end
    
    it "should raise an error when decoding 'COMM' and size set to 9 bits" do
      expect { 'COMM'.to_binary_array(9) }.to raise_error(ArgumentError)
    end

    it "should decode 'COMM' properly with size set to 8 bits" do
      eyeD3_version = [ 0, 1, 0, 0, 0, 0, 1, 1,
                        0, 1, 0, 0, 1, 1, 1, 1,
                        0, 1, 0, 0, 1, 1, 0, 1,
                        0, 1, 0, 0, 1, 1, 0, 1 ]
      expect('COMM'.to_binary_array(8)).to eq(eyeD3_version)
    end
    
    it "should decode 'COMM' properly with size set to 7 bits" do
      eyeD3_version = [ 1, 0, 0, 0, 0, 1, 1,
                        1, 0, 0, 1, 1, 1, 1,
                        1, 0, 0, 1, 1, 0, 1,
                        1, 0, 0, 1, 1, 0, 1 ]
      expect('COMM'.to_binary_array(7)).to eq(eyeD3_version)
    end

    it "should decode 'COMM' properly with size set to 6 bits" do
      eyeD3_version = [ 0, 0, 0, 0, 1, 1,
                        0, 0, 1, 1, 1, 1,
                        0, 0, 1, 1, 0, 1,
                        0, 0, 1, 1, 0, 1 ]
      expect('COMM'.to_binary_array(6)).to eq(eyeD3_version)
    end

    it "should decode 'COMM' properly with size set to 5 bits" do
      eyeD3_version = [ 0, 0, 0, 1, 1,
                        0, 1, 1, 1, 1,
                        0, 1, 1, 0, 1,
                        0, 1, 1, 0, 1 ]
      expect('COMM'.to_binary_array(5)).to eq(eyeD3_version)
    end

    it "should decode 'COMM' properly with size set to 4 bits" do
      eyeD3_version = [ 0, 0, 1, 1,
                        1, 1, 1, 1,
                        1, 1, 0, 1,
                        1, 1, 0, 1 ]
      expect('COMM'.to_binary_array(4)).to eq(eyeD3_version)
    end

    it "should decode 'COMM' properly with size set to 3 bits" do
      eyeD3_version = [ 0, 1, 1,
                        1, 1, 1,
                        1, 0, 1,
                        1, 0, 1 ]
      expect('COMM'.to_binary_array(3)).to eq(eyeD3_version)
    end

    it "should decode 'COMM' properly with size set to 2 bits" do
      eyeD3_version = [ 1, 1,
                        1, 1,
                        0, 1,
                        0, 1 ]
      expect('COMM'.to_binary_array(2)).to eq(eyeD3_version)
    end

    it "should decode 'COMM' properly with size set to 1 bit" do
      eyeD3_version = [ 1,
                        1,
                        1,
                        1 ]
      expect('COMM'.to_binary_array(1)).to eq(eyeD3_version)
    end

    it "should raise an error when decoding 'COMM' and size set to 0 bits" do
      expect { 'COMM'.to_binary_array(0) }.to raise_error(ArgumentError)
    end

    it "should decode 'Schüß' properly" do
      eyeD3_version = [ 0, 1, 0, 1, 0, 0, 1, 1,
                        0, 1, 1, 0, 0, 0, 1, 1,
                        0, 1, 1, 0, 1, 0, 0, 0,
                        1, 1, 0, 0, 0, 0, 1, 1,
                        1, 0, 1, 1, 1, 1, 0, 0, 
                        1, 1, 0, 0, 0, 0, 1, 1, 
                        1, 0, 0, 1, 1, 1, 1, 1 ]
      expect("Schüß".to_binary_array).to eq(eyeD3_version)
    end
    
    it "should decode 'βρεγμένοι ξυλουργοί' properly" do
      eyeD3_version = [ 1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 0, 0, 1, 0,
                        1, 1, 0, 0, 1, 1, 1, 1,
                        1, 0, 0, 0, 0, 0, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 0, 1, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 0, 0, 1, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 1, 0, 0,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 0, 1, 1, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 1, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 1, 1, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 0, 0, 1,
                        0, 0, 1, 0, 0, 0, 0, 0,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 1, 1, 0,
                        1, 1, 0, 0, 1, 1, 1, 1,
                        1, 0, 0, 0, 0, 1, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 0, 1, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 1, 1, 1,
                        1, 1, 0, 0, 1, 1, 1, 1,
                        1, 0, 0, 0, 0, 1, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 1,
                        1, 0, 0, 0, 0, 0, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 0, 0, 1, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 1, 1, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 0, 1, 1, 1, 1 ]
      expect('βρεγμένοι ξυλουργοί'.to_binary_array).to eq(eyeD3_version)
    end
  end
  
  describe String, "when encoding strings into binary decimal values" do
    it "should translate the empty string to 0" do
      expect(''.to_binary_decimal).to eq(0)
    end
    
    it "should translate '0' to 48" do
      expect('0'.to_binary_decimal).to eq(48)
    end
    
    it "should translate 'COMM' to 1129270605" do
      expect('COMM'.to_binary_decimal).to eq(1129270605)
    end
    
    it "should translate 'Schüß' to a big number correctly" do
      expect('Schüß'.to_binary_decimal).to eq(23471724678661023)
    end
    
    it "should translate 'βρεγμένοι ξυλουργοί' to a very big number correctly" do
      expect('βρεγμένοι ξυλουργοί'.to_binary_decimal).to eq(102795956441010160399840664432602556901983423562101036141448956544289521866253643221552815)
    end
  end
  
  describe String, "when decoding synchsafe values into binary decimals" do
    it "should translate the empty string to 0" do
      expect(''.from_synchsafe_string).to eq(0)
    end
    
    it "should translate '0' to 48" do
      expect('0'.from_synchsafe_string).to eq(48)
    end
    
    it "should translate 65,536 back from a synchsafe version correctly" do
      expect(65_536.to_synchsafe_string.from_synchsafe_string).to eq(65_536)
    end
    
    it "should translate 2 ** 27 - 1 back from a synchsafe version correctly" do
      expect((2 ** 27 - 1).to_synchsafe_string.from_synchsafe_string).to eq((2 ** 27 - 1))
    end
    
    it "should notice \"0x81828384\" isn't synchsafe" do
      expect("\x81\x82\x83\x84".synchsafe?).to be false
    end
  end
  
  describe Array, "when encoding binary arrays into strings" do
    it "should turn the empty array back into the empty string" do
      expect([].to_binary_string).to eq('')
    end
    
    it "should turn [0] into a null character" do
      expect([0].to_binary_string).to eq("\x00")
    end

    it "should turn [1,1,1,1,1,1,1,1] into 0xFF without raising" do
      expect([1,1,1,1,1,1,1,1].to_binary_string).to eq("\xFF".b)
    end

    it "should turn [1,0,0,0,0,0,0,0] into 0x80 without raising" do
      expect([1,0,0,0,0,0,0,0].to_binary_string).to eq("\x80".b)
    end
    
    it "should turn [0, 0, 1, 1, 0, 0, 0, 0] back into '0'" do
      eyeD3_version = [ 0, 0, 1, 1, 0, 0, 0, 0 ]
      expect(eyeD3_version.to_binary_string).to eq('0')
    end
    
    it "should turn a 9-element array back into a string" do
      eyeD3_version = [ 0, 0, 1, 1, 0, 0, 0, 0, 1 ]
      expect(eyeD3_version.to_binary_string).to eq("\x00a")
    end
    
    it "should turn a 10-element array back into a string" do
      eyeD3_version = [ 0, 0, 1, 1, 0, 0, 0, 0, 1, 0 ]
      expect(eyeD3_version.to_binary_string).to eq("\x00\xc2")
    end
    
    it "should fail when converting an array with non-base 2 elements" do
      eyeD3_version = [ 0, 1, 2, 0, 0, 0, 0, 0 ]
      expect { eyeD3_version.to_binary_string }.to raise_error(ArgumentError)
    end
    
    it "should reencode 'COMM' properly" do
      eyeD3_version = [ 0, 1, 0, 0, 0, 0, 1, 1,
                        0, 1, 0, 0, 1, 1, 1, 1,
                        0, 1, 0, 0, 1, 1, 0, 1,
                        0, 1, 0, 0, 1, 1, 0, 1 ]
      expect(eyeD3_version.to_binary_string).to eq('COMM')
    end
    
    it "should reencode 'Schüß' properly" do
      eyeD3_version = [ 0, 1, 0, 1, 0, 0, 1, 1,
                        0, 1, 1, 0, 0, 0, 1, 1,
                        0, 1, 1, 0, 1, 0, 0, 0,
                        1, 1, 0, 0, 0, 0, 1, 1,
                        1, 0, 1, 1, 1, 1, 0, 0, 
                        1, 1, 0, 0, 0, 0, 1, 1, 
                        1, 0, 0, 1, 1, 1, 1, 1 ]
      expect(eyeD3_version.to_binary_string).to eq("Schüß")
    end
    
    it "should reconstitute 'βρεγμένοι ξυλουργοί'" do
      eyeD3_version = [ 1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 0, 0, 1, 0,
                        1, 1, 0, 0, 1, 1, 1, 1,
                        1, 0, 0, 0, 0, 0, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 0, 1, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 0, 0, 1, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 1, 0, 0,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 0, 1, 1, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 1, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 1, 1, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 0, 0, 1,
                        0, 0, 1, 0, 0, 0, 0, 0,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 1, 1, 0,
                        1, 1, 0, 0, 1, 1, 1, 1,
                        1, 0, 0, 0, 0, 1, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 0, 1, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 1, 1, 1,
                        1, 1, 0, 0, 1, 1, 1, 1,
                        1, 0, 0, 0, 0, 1, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 1,
                        1, 0, 0, 0, 0, 0, 0, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 0, 0, 1, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 1, 1, 1, 1, 1,
                        1, 1, 0, 0, 1, 1, 1, 0,
                        1, 0, 1, 0, 1, 1, 1, 1 ]

      python_reconstituted = "\xce\xb2\xcf\x81\xce\xb5\xce\xb3\xce\xbc\xce\xad\xce\xbd\xce\xbf\xce\xb9 \xce\xbe\xcf\x85\xce\xbb\xce\xbf\xcf\x85\xcf\x81\xce\xb3\xce\xbf\xce\xaf"
      expect(python_reconstituted).to eq('βρεγμένοι ξυλουργοί')
      expect(eyeD3_version.to_binary_string).to eq(python_reconstituted)
    end
  end
  
  describe Array, "when encoding binary arrays into decimal values" do
    it "should encode [] into 0" do
      expect([].to_binary_decimal).to eq(0)
    end

    it "should encode [0] into 0" do
      expect([ 0 ].to_binary_decimal).to eq(0)
    end

    it "should fail when converting an array with non-base 2 elements" do
      expect { [ 0, 0, 2, 0, 0 ].to_binary_decimal }.to raise_error(ArgumentError)
    end

    it "should encode [1, 0, 0, 1, 1, 0] into 38" do
      expect([ 1, 0, 0, 1, 1, 0 ].to_binary_decimal).to eq(38)
    end

    it "should encode [0, 0, 1, 0, 0, 1, 1, 0] into 38" do
      expect([ 0, 0, 1, 0, 0, 1, 1, 0 ].to_binary_decimal).to eq(38)
    end
    
    it "should encode [1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0] into 14923952" do
      expect([ 1, 1, 1, 0, 0, 0, 1, 1,
        1, 0, 1, 1, 1, 0, 0, 0,
        1, 0, 1, 1, 0, 0, 0, 0 ].to_binary_decimal).to eq(14923952)
    end
  end
  
  describe Integer, "when encoding integers into binary arrays" do
    it "should raise an error when trying to translate -1" do
      expect { -1.to_binary_array }.to raise_error(ArgumentError)
    end
    
    it "should raise an error when padding is less than 0" do
      expect { 0.to_binary_array(-5) }.to raise_error(ArgumentError)
    end
    
    it "should translate 0 to []" do
      expect(0.to_binary_array).to eq([])
    end
    
    it "should translate 0 to [] when padding is set to 0" do
      expect(0.to_binary_array(0)).to eq([])
    end
    
    it "should translate 0 to [0] when padding is set to 1" do
      expect(0.to_binary_array(1)).to eq([ 0 ])
    end
    
    it "should translate 0 to [0,0] when padding is set to 2" do
      expect(0.to_binary_array(2)).to eq([ 0, 0 ])
    end
    
    it "should translate 0 to [0,0,0] when padding is set to 3" do
      expect(0.to_binary_array(3)).to eq([ 0, 0, 0 ])
    end
    
    it "should translate 0 to [0,0,0,0] when padding is set to 4" do
      expect(0.to_binary_array(4)).to eq([ 0, 0, 0, 0 ])
    end
    
    it "should translate 0 to [0,0,0,0,0] when padding is set to 5" do
      expect(0.to_binary_array(5)).to eq([ 0, 0, 0, 0, 0 ])
    end
    
    it "should translate 0 to [0,0,0,0,0,0] when padding is set to 6" do
      expect(0.to_binary_array(6)).to eq([ 0, 0, 0, 0, 0, 0 ])
    end
    
    it "should translate 0 to [0,0,0,0,0,0,0] when padding is set to 7" do
      expect(0.to_binary_array(7)).to eq([ 0, 0, 0, 0, 0, 0, 0 ])
    end
    
    it "should translate 0 to [0,0,0,0,0,0,0,0] when padding is set to 8" do
      expect(0.to_binary_array(8)).to eq([ 0, 0, 0, 0, 0, 0, 0, 0 ])
    end
    
    it "should translate 13 to [1,1,0,1] when padding is set to 0" do
      expect(13.to_binary_array(0)).to eq([ 1, 1, 0, 1 ])
    end
    
    it "should translate 13 to [1,1,0,1] when padding is set to 1" do
      expect(13.to_binary_array(1)).to eq([ 1, 1, 0, 1 ])
    end
    
    it "should translate 13 to [1,1,0,1] when padding is set to 2" do
      expect(13.to_binary_array(2)).to eq([ 1, 1, 0, 1 ])
    end
    
    it "should translate 13 to [1,1,0,1] when padding is set to 3" do
      expect(13.to_binary_array(3)).to eq([ 1, 1, 0, 1 ])
    end
    
    it "should translate 13 to [1,1,0,1] when padding is set to 4" do
      expect(13.to_binary_array(4)).to eq([ 1, 1, 0, 1 ])
    end
    
    it "should translate 13 to [0,1,1,1,1] when padding is set to 5" do
      expect(13.to_binary_array(5)).to eq([ 0, 1, 1, 0, 1 ])
    end
    
    it "should translate 13 to [0,0,1,1,0,1] when padding is set to 6" do
      expect(13.to_binary_array(6)).to eq([ 0, 0, 1, 1, 0, 1 ])
    end
    
    it "should translate 13 to [0,0,0,1,1,0,1] when padding is set to 7" do
      expect(13.to_binary_array(7)).to eq([ 0, 0, 0, 1, 1, 0, 1 ])
    end
    
    it "should translate 13 to [0,0,0,0,1,1,0,1] when padding is set to 8" do
      expect(13.to_binary_array(8)).to eq([ 0, 0, 0, 0, 1, 1, 0, 1 ])
    end
    
    it "should translate 48 to [1,1,0,0,0,0]" do
      expect(48.to_binary_array).to eq([ 1, 1, 0, 0, 0, 0 ])
    end
    
    it "should translate 48 to [0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0] when padding is set to 16" do
      eyeD3_version = [ 0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 1, 1, 0, 0, 0, 0 ]
      expect(48.to_binary_array(16)).to eq(eyeD3_version)
    end
    
    it "should translate 14923952 to binary array" do
      eyeD3_version = [ 1, 1, 1, 0, 0, 0, 1, 1,
                        1, 0, 1, 1, 1, 0, 0, 0,
                        1, 0, 1, 1, 0, 0, 0, 0 ]
      expect(14923952.to_binary_array).to eq(eyeD3_version)
    end
  end

  describe Integer, "when encoding integers into binary arrays" do
    it "should raise an error when trying to translate -1" do
      expect { -1.to_binary_string }.to raise_error(ArgumentError)
    end
    
    it "should raise an error when padding is less than 0" do
      expect { 0.to_binary_string(-5) }.to raise_error(ArgumentError)
    end
    
    it "should translate 0 to the empty string" do
      expect(0.to_binary_string).to eq('')
    end
    
    it "should translate 48 back to '0'" do
      expect(48.to_binary_string).to eq('0')
    end
    
    it "should translate 48 back to '\\x000' with a padding of 16" do
      expect(48.to_binary_string(16)).to eq("\x000")
    end
    
    it "should translate 48 back to '\\x00\\x000' with a padding of 19" do
      expect(48.to_binary_string(19)).to eq("\x00\x000")
    end
    
    it "should translate 1129270605 back to 'COMM'" do
      expect(1129270605.to_binary_string).to eq('COMM')
    end
    
    it "should translate a big number back to 'Schüß'" do
      expect(23471724678661023.to_binary_string).to eq('Schüß')
    end
    
    it "should translate a very big number back to 'βρεγμένοι ξυλουργοί'" do
      expect(102795956441010160399840664432602556901983423562101036141448956544289521866253643221552815.to_binary_string).to eq('βρεγμένοι ξυλουργοί')
    end
  end
  
  describe Integer, "when converting to synchsafe byte array (string)" do
    it "should raise an error when trying to translate -1" do
      expect { -1.to_synchsafe_string }.to raise_error(ArgumentError)
    end
    
    it "should raise an error when trying to translate number larger than 268435455" do
      expect { 268435456.to_synchsafe_string }.to raise_error(ArgumentError)
    end
    
    it "should convert 0 to '\\x00\\x00\\x00\\x00'" do
      expect(0.to_synchsafe_string).to eq("\x00\x00\x00\x00")
    end
    
    it "should convert 18 to '\\x00\\x00\\x00\\x12'" do
      expect(18.to_synchsafe_string).to eq("\x00\x00\x00\x12")
    end
    
    it "should convert 268,435,455 to '\\x7f\\x7f\\x7f\\x7f'" do
      expect(268_435_455.to_synchsafe_string).to eq("\x7f\x7f\x7f\x7f")
    end
    
    it "should convert 4,411,213 to '\\x02\\r\\x1eM'" do
      expect(4_411_213.to_synchsafe_string).to eq("\x02\r\x1eM")
    end
    
    it "should throw an error when trying to convert a number > 268,435,455 to a synchsafe string" do
      expect { 2_172_814_212.to_synchsafe_string }.to raise_error(ArgumentError)
    end
  end
  
  describe MPEGUtils, "when chaining functions" do
    it "should leave the empty string alone" do
      expect(''.to_binary_array.to_binary_string).to eq('')
    end
    
    it "should leave a string of null characters alone" do
      lotsa_nulls = 0.chr * 253
      expect(lotsa_nulls.to_binary_array.to_binary_string).to eq(lotsa_nulls)
    end
    
    it "should leave 'COMM' alone" do
      expect('COMM'.to_binary_array.to_binary_string).to eq('COMM')
    end
    
    it "should leave 'Schüß' alone" do
      expect('Schüß'.to_binary_array.to_binary_string).to eq('Schüß')
    end
    
    it "should leave 'βρεγμένοι ξυλουργοί' alone" do
      expect('βρεγμένοι ξυλουργοί'.to_binary_array.to_binary_string).to eq('βρεγμένοι ξυλουργοί')
    end
    
    it "should be able to handle totally pathological pipelines" do
      expect('βρεγμένοι ξυλουργοί'.to_binary_array.to_binary_decimal.to_binary_array.to_binary_string).to eq('βρεγμένοι ξυλουργοί')
    end
  end
end
