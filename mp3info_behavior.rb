$:.unshift("lib/")

require 'mp3info/mpeg_utils'
require 'mp3info/mpeg_header'

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
    
    it "should convert 268435455 to '\\x7f\\x7f\\x7f\\x7f'" do
      268435455.to_synchsafe_string.should == "\x7f\x7f\x7f\x7f"
    end
    
    it "should convert 4411213 to '\\x02\\r\\x1eM'" do
      4411213.to_synchsafe_string.should == "\x02\r\x1eM"
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

describe MPEGHeader, "parsing a variety of invalid MPEG headers" do
  it "should detect that '\\x00\\x00\\x00\\x00' is an invalid MPEG header" do
    header = MPEGHeader.new("\x00\x00\x00\x00")
    header.valid?.should == false
  end
  
  it "should detect that '\\xff\\xff\\xff\\xff' is an invalid MPEG header" do
    header = MPEGHeader.new("\xff\xff\xff\xff")
    header.valid?.should == false
  end
  
  it "should detect that provided header has an invalid sync stream in validity check" do
    invalid_header_array =
      [ 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,  # sync bitstream: changed (but how?)*
        1, 1,                             # version: 1.0
        0, 0,                             # layer: 0*
        1,                                # protected: has no CRC
        1, 0, 0, 1,                       # CBR bitrate: 128kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should detect that provided header has an invalid layer number in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 0,                             # layer: 0*
        1,                                # protected: has no CRC
        1, 0, 0, 1,                       # CBR bitrate: 128kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should raise an error when trying to access the layer in provided header" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 0,                             # layer: 0*
        1,                                # protected: has no CRC
        1, 0, 0, 1,                       # CBR bitrate: 128kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    lambda { MPEGHeader.new(invalid_header_array.to_binary_string).layer }.should raise_error(InvalidMPEGHeader)
  end
  
  it "should detect that provided header has an invalid version code in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        0, 1,                             # version: ?*
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 0, 0, 1,                       # CBR bitrate: 128kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should raise an error when trying to access the layer in provided header" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        0, 1,                             # version: ?*
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 0, 0, 1,                       # CBR bitrate: 128kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    lambda { MPEGHeader.new(invalid_header_array.to_binary_string).version }.should raise_error(InvalidMPEGHeader)
  end
  
  it "should detect that provided header has an invalid bitrate code (0x0f) in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 1, 1, 1,                       # CBR bitrate: reserved value*
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should raise an error when trying to access the bitrate (for code 0x0f) in provided header" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 1, 1, 1,                       # CBR bitrate: reserved value*
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    lambda { MPEGHeader.new(invalid_header_array.to_binary_string).bitrate }.should raise_error(InvalidMPEGHeader)
  end
  
  it "should raise an error when trying to access emphasis for invalid emphasis code in provided code" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 1, 0, 1,                       # CBR bitrate: 256
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        1, 1                              # emphasis: reserved value*
        ]
    lambda { MPEGHeader.new(invalid_header_array.to_binary_string).emphasis }.should raise_error(InvalidMPEGHeader)
  end
  
  it "should detect that provided header has an invalid sample frequency (3) in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 0, 0, 1,                       # CBR bitrate: 128kbps
        1, 1,                             # sample frequency: ?*
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should detect that provided header can't have a bitrate of 32 and a mode other than mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        0, 0, 0, 1,                       # CBR bitrate: 32kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).version.should == 1.0
    MPEGHeader.new(invalid_header_array.to_binary_string).layer.should == 2
    MPEGHeader.new(invalid_header_array.to_binary_string).bitrate.should == 32
    MPEGHeader.new(invalid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_JOINT_STEREO
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should detect that provided header can't have a bitrate of 48 and a mode other than mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        0, 0, 1, 0,                       # CBR bitrate: 48kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).version.should == 1.0
    MPEGHeader.new(invalid_header_array.to_binary_string).layer.should == 2
    MPEGHeader.new(invalid_header_array.to_binary_string).bitrate.should == 48
    MPEGHeader.new(invalid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_JOINT_STEREO
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should detect that provided header can't have a bitrate of 56 and a mode other than mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        0, 0, 1, 1,                       # CBR bitrate: 56kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).version.should == 1.0
    MPEGHeader.new(invalid_header_array.to_binary_string).layer.should == 2
    MPEGHeader.new(invalid_header_array.to_binary_string).bitrate.should == 56
    MPEGHeader.new(invalid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_JOINT_STEREO
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should detect that provided header can't have a bitrate of 80 and a mode other than mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        0, 1, 0, 1,                       # CBR bitrate: 80kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).version.should == 1.0
    MPEGHeader.new(invalid_header_array.to_binary_string).layer.should == 2
    MPEGHeader.new(invalid_header_array.to_binary_string).bitrate.should == 80
    MPEGHeader.new(invalid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_JOINT_STEREO
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should detect that provided header can't have a bitrate of 224 and be mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        1, 0, 1, 1,                       # CBR bitrate: 224kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        1, 1,                             # channel mode: mono*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        0,                                # original: no
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).version.should == 1.0
    MPEGHeader.new(invalid_header_array.to_binary_string).layer.should == 2
    MPEGHeader.new(invalid_header_array.to_binary_string).bitrate.should == 224
    MPEGHeader.new(invalid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_MONO
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should detect that provided header can't have a bitrate of 256 and be mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        1, 1, 0, 0,                       # CBR bitrate: 256kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        1, 1,                             # channel mode: mono*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        0,                                # original: no
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).version.should == 1.0
    MPEGHeader.new(invalid_header_array.to_binary_string).layer.should == 2
    MPEGHeader.new(invalid_header_array.to_binary_string).bitrate.should == 256
    MPEGHeader.new(invalid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_MONO
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should detect that provided header can't have a bitrate of 320 and be mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        1, 1, 0, 1,                       # CBR bitrate: 320kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        1, 1,                             # channel mode: mono*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        0,                                # original: no
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).version.should == 1.0
    MPEGHeader.new(invalid_header_array.to_binary_string).layer.should == 2
    MPEGHeader.new(invalid_header_array.to_binary_string).bitrate.should == 320
    MPEGHeader.new(invalid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_MONO
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should detect that provided header can't have a bitrate of 384 and be mono in validity check" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        1, 1, 1, 0,                       # CBR bitrate: 384kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        1, 1,                             # channel mode: mono*
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        0,                                # original: no
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).version.should == 1.0
    MPEGHeader.new(invalid_header_array.to_binary_string).layer.should == 2
    MPEGHeader.new(invalid_header_array.to_binary_string).bitrate.should == 384
    MPEGHeader.new(invalid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_MONO
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
  
  it "should detect that an MPEG 1.0 Layer III file can't have an emphasis of type RESERVED" do
    invalid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 0, 0, 1,                       # CBR bitrate: 128kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        1, 0                              # emphasis: reserved
        ]
    MPEGHeader.new(invalid_header_array.to_binary_string).emphasis.should == MPEGHeader::EMPHASIS_RESERVED
    MPEGHeader.new(invalid_header_array.to_binary_string).valid?.should == false
  end
end

describe MPEGHeader, "parsing a valid sample MPEG header" do
  before do
    sample_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 0, 0, 1,                       # CBR bitrate: 128kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    @sample_header = MPEGHeader.new(sample_header_array.to_binary_string)
  end
  
  it "should detect that sample header '\\xff\\xfb\\x90\\x64' is a valid MPEG header" do
    @sample_header.valid?.should == true
  end
  
  it "should detect that sample header comes from an MPEG version 1.0 frame" do
    @sample_header.version.should == 1.0
  end
  
  it "should detect that sample header comes from an MPEG layer 3 frame" do
    @sample_header.layer.should == 3
  end
  
  it "should detect that sample header comes from an unpadded frame" do
    @sample_header.padded_stream?.should be_false
  end
  
  it "should detect that sample header comes from a frame with no error protection" do
    @sample_header.error_protection.should be_false
  end
  
  it "should detect that sample header comes from a stream with a frame size of 417" do
    @sample_header.frame_size.should == 417
  end
  
  it "should detect that sample header comes from a frame with an MPEG CBR bitrate of 128" do
    @sample_header.bitrate.should == 128
  end
  
  it "should detect that sample header comes from a frame with a sample frequency of 44.1KHz" do
    @sample_header.sample_rate.should == 44_100
  end
  
  it "should detect that sample header comes from a frame with no emphasis" do
    @sample_header.emphasis.should == 'none'
  end
  
  it "should detect that sample header comes from a frame with a channel mode of 'Joint stereo'" do
    @sample_header.mode.should == MPEGHeader::MODE_JOINT_STEREO
  end
  
  it "should detect that sample header comes from a frame with intensity stereo turned off" do
    (@sample_header.mode_extension & MPEGHeader::MODE_EXTENSION_INTENSITY).should == 0
  end
  
  it "should detect that sample header comes from a frame with m/s stereo turned on" do
    (@sample_header.mode_extension & MPEGHeader::MODE_EXTENSION_M_S_STEREO).should == MPEGHeader::MODE_EXTENSION_M_S_STEREO
  end
  
  it "should detect that sample header comes from a frame with the private bit clear" do
    @sample_header.private_stream?.should be_false
  end
  
  it "should detect that sample header comes from a frame declared to not be copyrighted" do
    @sample_header.copyrighted_stream?.should be_false
  end
  
  it "should detect that sample header comes from a frame declared to be original content" do
    @sample_header.original_stream?.should be_true
  end
end

describe MPEGHeader, "with valid but unusual headers" do
  it "should detect CBR without errors for MPEG 2.5, layer 3 files" do
    valid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        0, 0,                             # version: 2.5
        0, 1,                             # layer: 3
        1,                                # protected: has no CRC
        1, 1, 0, 0,                       # CBR bitrate: 128kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(valid_header_array.to_binary_string).valid?.should == true
    MPEGHeader.new(valid_header_array.to_binary_string).bitrate.should == 128
  end
  
  it "should detect settings without errors for MPEG 2.5, layer 1 files" do
    valid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        0, 0,                             # version: 2.5
        1, 1,                             # layer: 1
        1,                                # protected: has no CRC
        1, 1, 0, 0,                       # CBR bitrate: 192kbps
        0, 0,                             # sample frequency: 11.025KHz
        1,                                # padding: padded
        1,                                # private: set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: bands 12 to 31
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).version.should == 2.5
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).valid?.should == true
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).bitrate.should == 192
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).sample_rate.should == 11_025
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).frame_size.should == 848
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_JOINT_STEREO
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).private_stream?.should == true
    # mode extension not supported by eyeD3
    (MPEGHeader.new(valid_header_array.to_binary_string).mode_extension & 
     MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31).should == MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31
  end
  
  it "should detect settings without errors for MPEG 2, layer 1 files" do
    valid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 0,                             # version: 2
        1, 1,                             # layer: 1
        1,                                # protected: has no CRC
        1, 1, 0, 0,                       # CBR bitrate: 192kbps
        0, 0,                             # sample frequency: 22.05KHz
        1,                                # padding: padded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: bands 12 to 31
        0,                                # copyrighted: no
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).version.should == 2
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).valid?.should == true
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).bitrate.should == 192
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).sample_rate.should == 22_050
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).frame_size.should == 432
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_JOINT_STEREO
    # verified against eyeD3
    MPEGHeader.new(valid_header_array.to_binary_string).private_stream?.should == false
    # mode extension not supported by eyeD3
    (MPEGHeader.new(valid_header_array.to_binary_string).mode_extension & 
     MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31).should == MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31
  end
  
  it "should detect settings without errors for MPEG 2.5, layer 2 files" do
    valid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        0, 0,                             # version: 2.5
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        1, 1, 0, 0,                       # CBR bitrate: 128kbps
        0, 0,                             # sample frequency: 11.025KHz
        1,                                # padding: padded
        0,                                # private: not set
        0, 1,                             # channel mode: joint stereo
        1, 0,                             # channel mode extension: bands 12 to 31
        1,                                # copyrighted: yes
        1,                                # original: yes
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(valid_header_array.to_binary_string).version.should == 2.5
    MPEGHeader.new(valid_header_array.to_binary_string).layer.should == 2
    MPEGHeader.new(valid_header_array.to_binary_string).bitrate.should == 128
    MPEGHeader.new(valid_header_array.to_binary_string).sample_rate.should == 11_025
    MPEGHeader.new(valid_header_array.to_binary_string).frame_size.should == 1672
    MPEGHeader.new(valid_header_array.to_binary_string).copyrighted_stream?.should == true
    MPEGHeader.new(valid_header_array.to_binary_string).original_stream?.should == true
    MPEGHeader.new(valid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_JOINT_STEREO
    MPEGHeader.new(valid_header_array.to_binary_string).valid?.should == true
    MPEGHeader.new(valid_header_array.to_binary_string).private_stream?.should == false
    # mode extension not supported by eyeD3
    (MPEGHeader.new(valid_header_array.to_binary_string).mode_extension & 
     MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31).should == MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31
  end
  
  it "should handle a bitrate of 80 and a mode of mono" do
    valid_header_array =
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  # sync bitstream: CONSTANT
        1, 1,                             # version: 1.0
        1, 0,                             # layer: 2
        1,                                # protected: has no CRC
        0, 1, 0, 1,                       # CBR bitrate: 80kbps
        0, 0,                             # sample frequency: 44.1KHz
        0,                                # padding: unpadded
        0,                                # private: not set
        1, 1,                             # channel mode: mono
        1, 0,                             # channel mode extension: intensity off, MS on
        0,                                # copyrighted: no
        0,                                # original: no
        0, 0                              # emphasis: none
        ]
    MPEGHeader.new(valid_header_array.to_binary_string).version.should == 1.0
    MPEGHeader.new(valid_header_array.to_binary_string).layer.should == 2
    MPEGHeader.new(valid_header_array.to_binary_string).valid?.should == true
    MPEGHeader.new(valid_header_array.to_binary_string).bitrate.should == 80
    MPEGHeader.new(valid_header_array.to_binary_string).sample_rate.should == 44_100
    MPEGHeader.new(valid_header_array.to_binary_string).frame_size.should == 261
    MPEGHeader.new(valid_header_array.to_binary_string).mode.should == MPEGHeader::MODE_MONO
    MPEGHeader.new(valid_header_array.to_binary_string).private_stream?.should == false
    # mode extension not supported by eyeD3
    (MPEGHeader.new(valid_header_array.to_binary_string).mode_extension & 
     MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31).should == MPEGHeader::MODE_EXTENSION_BANDS_12_TO_31
  end
end
