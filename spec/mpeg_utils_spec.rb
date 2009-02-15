# encoding: binary
$:.unshift("lib/")

require 'mp3info/mpeg_utils'

module MPEGUtils
  describe String, "when decoding strings into binary arrays" do
    it "should decode the empty string into the empty array" do
      ''.to_binary_array.should == []
    end

    it "should decode '0' into [0, 0, 1, 1, 0, 0, 0, 0]" do
      eyeD3_version = [ 0, 0, 1, 1, 0, 0, 0, 0 ]
      '0'.to_binary_array.should == eyeD3_version
    end

    it "should decode 'COMM' properly" do
      eyeD3_version = [ 0, 1, 0, 0, 0, 0, 1, 1,
                        0, 1, 0, 0, 1, 1, 1, 1,
                        0, 1, 0, 0, 1, 1, 0, 1,
                        0, 1, 0, 0, 1, 1, 0, 1 ]
      'COMM'.to_binary_array.should == eyeD3_version
    end
    
    it "should raise an error when decoding 'COMM' and size set to 9 bits" do
      lambda { 'COMM'.to_binary_array(9) }.should raise_error(ArgumentError)
    end

    it "should decode 'COMM' properly with size set to 8 bits" do
      eyeD3_version = [ 0, 1, 0, 0, 0, 0, 1, 1,
                        0, 1, 0, 0, 1, 1, 1, 1,
                        0, 1, 0, 0, 1, 1, 0, 1,
                        0, 1, 0, 0, 1, 1, 0, 1 ]
      'COMM'.to_binary_array(8).should == eyeD3_version
    end
    
    it "should decode 'COMM' properly with size set to 7 bits" do
      eyeD3_version = [ 1, 0, 0, 0, 0, 1, 1,
                        1, 0, 0, 1, 1, 1, 1,
                        1, 0, 0, 1, 1, 0, 1,
                        1, 0, 0, 1, 1, 0, 1 ]
      'COMM'.to_binary_array(7).should == eyeD3_version
    end

    it "should decode 'COMM' properly with size set to 6 bits" do
      eyeD3_version = [ 0, 0, 0, 0, 1, 1,
                        0, 0, 1, 1, 1, 1,
                        0, 0, 1, 1, 0, 1,
                        0, 0, 1, 1, 0, 1 ]
      'COMM'.to_binary_array(6).should == eyeD3_version
    end

    it "should decode 'COMM' properly with size set to 5 bits" do
      eyeD3_version = [ 0, 0, 0, 1, 1,
                        0, 1, 1, 1, 1,
                        0, 1, 1, 0, 1,
                        0, 1, 1, 0, 1 ]
      'COMM'.to_binary_array(5).should == eyeD3_version
    end

    it "should decode 'COMM' properly with size set to 4 bits" do
      eyeD3_version = [ 0, 0, 1, 1,
                        1, 1, 1, 1,
                        1, 1, 0, 1,
                        1, 1, 0, 1 ]
      'COMM'.to_binary_array(4).should == eyeD3_version
    end

    it "should decode 'COMM' properly with size set to 3 bits" do
      eyeD3_version = [ 0, 1, 1,
                        1, 1, 1,
                        1, 0, 1,
                        1, 0, 1 ]
      'COMM'.to_binary_array(3).should == eyeD3_version
    end

    it "should decode 'COMM' properly with size set to 2 bits" do
      eyeD3_version = [ 1, 1,
                        1, 1,
                        0, 1,
                        0, 1 ]
      'COMM'.to_binary_array(2).should == eyeD3_version
    end

    it "should decode 'COMM' properly with size set to 1 bit" do
      eyeD3_version = [ 1,
                        1,
                        1,
                        1 ]
      'COMM'.to_binary_array(1).should == eyeD3_version
    end

    it "should raise an error when decoding 'COMM' and size set to 0 bits" do
      lambda { 'COMM'.to_binary_array(0) }.should raise_error(ArgumentError)
    end

    it "should decode 'Schüß' properly" do
      eyeD3_version = [ 0, 1, 0, 1, 0, 0, 1, 1,
                        0, 1, 1, 0, 0, 0, 1, 1,
                        0, 1, 1, 0, 1, 0, 0, 0,
                        1, 1, 0, 0, 0, 0, 1, 1,
                        1, 0, 1, 1, 1, 1, 0, 0, 
                        1, 1, 0, 0, 0, 0, 1, 1, 
                        1, 0, 0, 1, 1, 1, 1, 1 ]
      "Schüß".to_binary_array.should == eyeD3_version
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
      'βρεγμένοι ξυλουργοί'.to_binary_array.should == eyeD3_version
    end
  end
  
  describe String, "when encoding strings into binary decimal values" do
    it "should translate the empty string to 0" do
      ''.to_binary_decimal.should == 0
    end
    
    it "should translate '0' to 48" do
      '0'.to_binary_decimal.should == 48
    end
    
    it "should translate 'COMM' to 1129270605" do
      'COMM'.to_binary_decimal.should == 1129270605
    end
    
    it "should translate 'Schüß' to a big number correctly" do
      'Schüß'.to_binary_decimal.should == 23471724678661023
    end
    
    it "should translate 'βρεγμένοι ξυλουργοί' to a very big number correctly" do
      'βρεγμένοι ξυλουργοί'.to_binary_decimal.should == 102795956441010160399840664432602556901983423562101036141448956544289521866253643221552815
    end
  end
  
  describe String, "when decoding synchsafe values into binary decimals" do
    it "should translate the empty string to 0" do
      ''.from_synchsafe_string.should == 0
    end
    
    it "should translate '0' to 48" do
      '0'.from_synchsafe_string.should == 48
    end
    
    it "should translate 65,536 back from a synchsafe version correctly" do
      65_536.to_synchsafe_string.from_synchsafe_string.should == 65_536
    end
    
    it "should translate 2 ** 27 - 1 back from a synchsafe version correctly" do
      (2 ** 27 - 1).to_synchsafe_string.from_synchsafe_string.should == (2 ** 27 - 1)
    end
    
    it "should translate \"0x81828384\" to 2,172,814,212, even though the source isn't synchsafe and the result is a Bignum" do
      "\x81\x82\x83\x84".from_synchsafe_string.should == 2_172_814_212
    end
  end
  
  describe Array, "when encoding binary arrays into strings" do
    it "should turn the empty array back into the empty string" do
      [].to_binary_string.should == ''
    end
    
    it "should turn [0] into a null character" do
      [0].to_binary_string.should == "\x00"
    end
    
    it "should turn [0, 0, 1, 1, 0, 0, 0, 0] back into '0'" do
      eyeD3_version = [ 0, 0, 1, 1, 0, 0, 0, 0 ]
      eyeD3_version.to_binary_string.should == '0'
    end
    
    it "should turn a 9-element array back into a string" do
      eyeD3_version = [ 0, 0, 1, 1, 0, 0, 0, 0, 1 ]
      eyeD3_version.to_binary_string.should == "\x00a"
    end
    
    it "should turn a 10-element array back into a string" do
      eyeD3_version = [ 0, 0, 1, 1, 0, 0, 0, 0, 1, 0 ]
      eyeD3_version.to_binary_string.should == "\x00\xc2"
    end
    
    it "should fail when converting an array with non-base 2 elements" do
      eyeD3_version = [ 0, 1, 2, 0, 0, 0, 0, 0 ]
      lambda { eyeD3_version.to_binary_string }.should raise_error(ArgumentError)
    end
    
    it "should reencode 'COMM' properly" do
      eyeD3_version = [ 0, 1, 0, 0, 0, 0, 1, 1,
                        0, 1, 0, 0, 1, 1, 1, 1,
                        0, 1, 0, 0, 1, 1, 0, 1,
                        0, 1, 0, 0, 1, 1, 0, 1 ]
      eyeD3_version.to_binary_string.should == 'COMM'
    end
    
    it "should reencode 'Schüß' properly" do
      eyeD3_version = [ 0, 1, 0, 1, 0, 0, 1, 1,
                        0, 1, 1, 0, 0, 0, 1, 1,
                        0, 1, 1, 0, 1, 0, 0, 0,
                        1, 1, 0, 0, 0, 0, 1, 1,
                        1, 0, 1, 1, 1, 1, 0, 0, 
                        1, 1, 0, 0, 0, 0, 1, 1, 
                        1, 0, 0, 1, 1, 1, 1, 1 ]
      eyeD3_version.to_binary_string.should == "Schüß"
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
      python_reconstituted.should == 'βρεγμένοι ξυλουργοί'
      eyeD3_version.to_binary_string.should == python_reconstituted
    end
  end
  
  describe Array, "when encoding binary arrays into decimal values" do
    it "should encode [] into 0" do
      [].to_binary_decimal.should == 0
    end

    it "should encode [0] into 0" do
      [ 0 ].to_binary_decimal.should == 0
    end

    it "should fail when converting an array with non-base 2 elements" do
      lambda { [ 0, 0, 2, 0, 0 ].to_binary_decimal }.should raise_error(ArgumentError)
    end

    it "should encode [1, 0, 0, 1, 1, 0] into 38" do
      [ 1, 0, 0, 1, 1, 0 ].to_binary_decimal.should == 38
    end

    it "should encode [0, 0, 1, 0, 0, 1, 1, 0] into 38" do
      [ 0, 0, 1, 0, 0, 1, 1, 0 ].to_binary_decimal.should == 38
    end
    
    it "should encode [1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0] into 14923952" do
      [ 1, 1, 1, 0, 0, 0, 1, 1,
        1, 0, 1, 1, 1, 0, 0, 0,
        1, 0, 1, 1, 0, 0, 0, 0 ].to_binary_decimal.should == 14923952
    end
  end
  
  describe Fixnum, "when encoding integers into binary arrays" do
    it "should raise an error when trying to translate -1" do
      lambda { -1.to_binary_array }.should raise_error(ArgumentError)
    end
    
    it "should raise an error when padding is less than 0" do
      lambda { 0.to_binary_array(-5) }.should raise_error(ArgumentError)
    end
    
    it "should translate 0 to []" do
      0.to_binary_array.should == []
    end
    
    it "should translate 0 to [] when padding is set to 0" do
      0.to_binary_array(0).should == []
    end
    
    it "should translate 0 to [0] when padding is set to 1" do
      0.to_binary_array(1).should == [ 0 ]
    end
    
    it "should translate 0 to [0,0] when padding is set to 2" do
      0.to_binary_array(2).should == [ 0, 0 ]
    end
    
    it "should translate 0 to [0,0,0] when padding is set to 3" do
      0.to_binary_array(3).should == [ 0, 0, 0 ]
    end
    
    it "should translate 0 to [0,0,0,0] when padding is set to 4" do
      0.to_binary_array(4).should == [ 0, 0, 0, 0 ]
    end
    
    it "should translate 0 to [0,0,0,0,0] when padding is set to 5" do
      0.to_binary_array(5).should == [ 0, 0, 0, 0, 0 ]
    end
    
    it "should translate 0 to [0,0,0,0,0,0] when padding is set to 6" do
      0.to_binary_array(6).should == [ 0, 0, 0, 0, 0, 0 ]
    end
    
    it "should translate 0 to [0,0,0,0,0,0,0] when padding is set to 7" do
      0.to_binary_array(7).should == [ 0, 0, 0, 0, 0, 0, 0 ]
    end
    
    it "should translate 0 to [0,0,0,0,0,0,0,0] when padding is set to 8" do
      0.to_binary_array(8).should == [ 0, 0, 0, 0, 0, 0, 0, 0 ]
    end
    
    it "should translate 13 to [1,1,0,1] when padding is set to 0" do
      13.to_binary_array(0).should == [ 1, 1, 0, 1 ]
    end
    
    it "should translate 13 to [1,1,0,1] when padding is set to 1" do
      13.to_binary_array(1).should == [ 1, 1, 0, 1 ]
    end
    
    it "should translate 13 to [1,1,0,1] when padding is set to 2" do
      13.to_binary_array(2).should == [ 1, 1, 0, 1 ]
    end
    
    it "should translate 13 to [1,1,0,1] when padding is set to 3" do
      13.to_binary_array(3).should == [ 1, 1, 0, 1 ]
    end
    
    it "should translate 13 to [1,1,0,1] when padding is set to 4" do
      13.to_binary_array(4).should == [ 1, 1, 0, 1 ]
    end
    
    it "should translate 13 to [0,1,1,1,1] when padding is set to 5" do
      13.to_binary_array(5).should == [ 0, 1, 1, 0, 1 ]
    end
    
    it "should translate 13 to [0,0,1,1,0,1] when padding is set to 6" do
      13.to_binary_array(6).should == [ 0, 0, 1, 1, 0, 1 ]
    end
    
    it "should translate 13 to [0,0,0,1,1,0,1] when padding is set to 7" do
      13.to_binary_array(7).should == [ 0, 0, 0, 1, 1, 0, 1 ]
    end
    
    it "should translate 13 to [0,0,0,0,1,1,0,1] when padding is set to 8" do
      13.to_binary_array(8).should == [ 0, 0, 0, 0, 1, 1, 0, 1 ]
    end
    
    it "should translate 48 to [1,1,0,0,0,0]" do
      48.to_binary_array.should == [ 1, 1, 0, 0, 0, 0 ]
    end
    
    it "should translate 48 to [0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0] when padding is set to 16" do
      eyeD3_version = [ 0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 1, 1, 0, 0, 0, 0 ]
      48.to_binary_array(16).should == eyeD3_version
    end
    
    it "should translate 14923952 to binary array" do
      eyeD3_version = [ 1, 1, 1, 0, 0, 0, 1, 1,
                        1, 0, 1, 1, 1, 0, 0, 0,
                        1, 0, 1, 1, 0, 0, 0, 0 ]
      14923952.to_binary_array.should == eyeD3_version
    end
  end

  describe Fixnum, "when encoding integers into binary arrays" do
    it "should raise an error when trying to translate -1" do
      lambda { -1.to_binary_string }.should raise_error(ArgumentError)
    end
    
    it "should raise an error when padding is less than 0" do
      lambda { 0.to_binary_string(-5) }.should raise_error(ArgumentError)
    end
    
    it "should translate 0 to the empty string" do
      0.to_binary_string.should == ''
    end
    
    it "should translate 48 back to '0'" do
      48.to_binary_string.should == '0'
    end
    
    it "should translate 48 back to '\\x000' with a padding of 16" do
      48.to_binary_string(16).should == "\x000"
    end
    
    it "should translate 48 back to '\\x00\\x000' with a padding of 19" do
      48.to_binary_string(19).should == "\x00\x000"
    end
    
    it "should translate 1129270605 back to 'COMM'" do
      1129270605.to_binary_string.should == 'COMM'
    end
    
    it "should translate a big number back to 'Schüß'" do
      23471724678661023.to_binary_string.should == 'Schüß'
    end
    
    it "should translate a very big number back to 'βρεγμένοι ξυλουργοί'" do
      102795956441010160399840664432602556901983423562101036141448956544289521866253643221552815.to_binary_string.should == 'βρεγμένοι ξυλουργοί'
    end
  end
  
  describe Fixnum, "when converting to synchsafe byte array (string)" do
    it "should raise an error when trying to translate -1" do
      lambda { -1.to_synchsafe_string }.should raise_error(ArgumentError)
    end
    
    it "should raise an error when trying to translate number larger than 268435455" do
      lambda { 268435456.to_synchsafe_string }.should raise_error(ArgumentError)
    end
    
    it "should convert 0 to '\\x00\\x00\\x00\\x00'" do
      0.to_synchsafe_string.should == "\x00\x00\x00\x00"
    end
    
    it "should convert 18 to '\\x00\\x00\\x00\\x12'" do
      18.to_synchsafe_string.should == "\x00\x00\x00\x12"
    end
    
    it "should convert 268,435,455 to '\\x7f\\x7f\\x7f\\x7f'" do
      268_435_455.to_synchsafe_string.should == "\x7f\x7f\x7f\x7f"
    end
    
    it "should convert 4,411,213 to '\\x02\\r\\x1eM'" do
      4_411_213.to_synchsafe_string.should == "\x02\r\x1eM"
    end
    
    it "should throw an error when trying to convert a Bignum (2,172,814,212) to a synchsafe string (see String specs)" do
      lambda { 2_172_814_212.to_synchsafe_string.should == "foo" }.should raise_error(NoMethodError, "undefined method `to_synchsafe_string' for 2172814212:Bignum")
    end
  end
  
  describe MPEGUtils, "when chaining functions" do
    it "should leave the empty string alone" do
      ''.to_binary_array.to_binary_string.should == ''
    end
    
    it "should leave a string of null characters alone" do
      lotsa_nulls = 0.chr * 253
      lotsa_nulls.to_binary_array.to_binary_string.should == lotsa_nulls;
    end
    
    it "should leave 'COMM' alone" do
      'COMM'.to_binary_array.to_binary_string.should == 'COMM';
    end
    
    it "should leave 'Schüß' alone" do
      'Schüß'.to_binary_array.to_binary_string.should == 'Schüß';
    end
    
    it "should leave 'βρεγμένοι ξυλουργοί' alone" do
      'βρεγμένοι ξυλουργοί'.to_binary_array.to_binary_string.should == 'βρεγμένοι ξυλουργοί';
    end
    
    it "should be able to handle totally pathological pipelines" do
      'βρεγμένοι ξυλουργοί'.to_binary_array.to_binary_decimal.to_binary_array.to_binary_string.should == 'βρεγμένοι ξυλουργοί'
    end
  end
end
