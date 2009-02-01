$:.unshift("lib/")

require 'base64'
require 'digest/sha1'
require 'mp3info'

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

module Mp3InfoHelper
  TEST_TITLE        = "No Backrub"
  TEST_ARTIST       = "Bikini Kill"
  TEST_ALBUM        = "Reject All American"
  TEST_YEAR         = "1996"
  TEST_COMMENT      = "Feminism ruelz!"
  TEST_TRACK_NUMBER = 7
  TEST_GENRE_ID     = 43
  # ID3v1 genre ID 43 -> Punk
  TEST_GENRE_NAME   = "Punk"
  
  # not in the ID3v1 list of genres or the WinAmp extension list
  INVALID_GENRE_ID  = 253
  
  def get_valid_mp3
        # Command to create a dummy MP3
        # dd if=/dev/zero bs=1024 count=15 | lame --preset cbr 128 -r -s 44.1 --bitwidth 16 - - | ruby -rbase64 -e 'print Base64.encode64($stdin.read)'
    Base64.decode64 <<EOF
//uQZAAAAAAAaQYAAAAAAA0gwAAAAAABpBwAAAAAADSDgAAATEFNRTMuOTNV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVTEFNRTMuOTNVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVV//uSZL6P8AAAaQAAAAAAAA0gAAAAAAABpAAAAAAAADSA
AAAAVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjkzVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVf/7kmT/j/AAAGkAAAAAAAANIAAA
AAAAAaQAAAAAAAA0gAAAAFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVM
QU1FMy45M1VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+5Jk/4/w
AABpAAAAAAAADSAAAAAAAAGkAAAAAAAANIAAAABVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVTEFNRTMuOTNVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVV//uSZP+P8AAAaQAAAAAAAA0gAAAAAAABpAAAAAAAADSAAAAAVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVQ==
EOF
  end
  
  def create_sample_mp3_file(filename)
    File.open(filename, "w") { |f| f.write(get_valid_mp3) }
  end
  
  def sample_id3v1_0_attrs
    [ TEST_TITLE,
      TEST_ARTIST,
      TEST_ALBUM,
      TEST_YEAR,
      TEST_COMMENT,
      TEST_GENRE_ID ]
  end
  
  def sample_id3v1_1_attrs
    [ TEST_TITLE,
      TEST_ARTIST,
      TEST_ALBUM,
      TEST_YEAR,
      TEST_COMMENT,
      TEST_TRACK_NUMBER,
      TEST_GENRE_ID ]
  end
  
  def sample_id3v1_tag
    { "title"    => TEST_TITLE,
      "artist"   => TEST_ARTIST,
      "album"    => TEST_ALBUM,
      "year"     => TEST_YEAR,
      "comments" => TEST_COMMENT,
      "genre"    => TEST_GENRE_ID,
      "genre_s"  => TEST_GENRE_NAME,
      "tracknum" => TEST_TRACK_NUMBER }
  end
  
  def sample_id3v2_tag
    { "COMM" => ID3V24::Frame.create_frame("COMM", TEST_COMMENT),
      "TCON" => ID3V24::Frame.create_frame("TCON", TEST_GENRE_NAME),
      "TIT2" => ID3V24::Frame.create_frame("TIT2", TEST_TITLE),
      "TPE1" => ID3V24::Frame.create_frame("TPE1", TEST_ARTIST),
      "TALB" => ID3V24::Frame.create_frame("TALB", TEST_ALBUM),
      "TYER" => ID3V24::Frame.create_frame("TYER", TEST_YEAR),
      "TRCK" => ID3V24::Frame.create_frame("TRCK", "#{TEST_TRACK_NUMBER}/12") }
  end
  
  def random_string(size)
    out = ""
    size.times { out << rand(256).chr }
    out
  end
  
  def create_valid_id3_1_0_file(filename)
    File.open(filename, "w") do |f|
      f.write(get_valid_mp3)
      # brutally low-level means of writing an ID3 tag on its own
      f.write("TAG#{sample_id3v1_0_attrs.pack('A30A30A30A4A30C')}")
    end
  end
  
  def create_valid_id3_1_1_file(filename)
    File.open(filename, "w") do |f|
      f.write(get_valid_mp3)
      # brutally low-level means of writing an ID3v1.1 tag on its own
      f.write("TAG#{sample_id3v1_1_attrs.pack('A30A30A30A4a29CC')}")
    end
  end
  
  def update_id3_2_tag(filename, tag)
    Mp3Info.open(filename) do |mp3|
      mp3.tag2.update(tag)
    end
    
    Mp3Info.open(filename) { |m| m.tag2 }
  end
  
  def test_against_id3v2_prog(written_tag)
    return if PLATFORM =~ /win32/
    return if `which id3v2`.empty?
    
    start = false
    id3v2_output = {}
    `id3v2 -l #{@mp3_filename}`.each do |line|
      if line =~ /^id3v2 tag info/
        start = true
        next
      end
      next unless start
      k, v = /^(.{4}) \(.+\): (.+)$/.match(line)[1,2]
      
      #COMM (Comments): ()[spa]: fmg
      v.sub!(/\(\)\[.{3}\]: (.+)/, '\1') if k == "COMM"
      
      id3v2_output[k] = v
    end
    
    id3v2_output
  end
  
  def prettify_tag(tag)
    prettified_tag = {}
    
    tag.each do |key,value|
      prettified_tag[key] = value.to_s_pretty
    end
    
    prettified_tag
  end
end

describe Mp3Info, "when loading an invalid MP3 file" do
  before do
    @mp3_filename = "test_mp3info.mp3"
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should recognize when it's passed total garbage" do
    File.open(@mp3_filename, "w") do |f|
      str = "0" * 32 * 1024
      f.write(str)
    end

    lambda { Mp3Info.new(@mp3_filename) }.should raise_error(Mp3InfoError, "cannot find a valid frame after reading 32768 bytes from #{@mp3_filename}")
  end
end

describe Mp3Info, "when loading a sample MP3 file" do
  include Mp3InfoHelper

  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should load a valid MP3 file without errors" do
    lambda { Mp3Info.new(@mp3_filename).close }.should_not raise_error(Mp3InfoError)
  end
  
  it "should successfully provide an Mp3Info object when opening a valid MP3 file" do
    Mp3Info.open(@mp3_filename) { |info| info.should be_a(Mp3Info) }
  end
  
  it "should return a string description when opening a valid MP3 file" do
    Mp3Info.open(@mp3_filename) { |info| info.to_s.should be_a(String) }
  end
  
  it "should detect that the sample file contains MPEG 1 audio" do
    Mp3Info.open(@mp3_filename) { |info| info.mpeg_version.should == 1 }
  end
  
  it "should detect that the sample file contains layer 3 audio" do
    Mp3Info.open(@mp3_filename) { |info| info.layer.should == 3 }
  end
  
  it "should detect that the sample file does not contain VBR-encoded audio" do
    Mp3Info.open(@mp3_filename) { |info| info.vbr.should_not be_true }
  end
  
  it "should detect that the sample file has a CBR bitrate of 128kbps" do
    Mp3Info.open(@mp3_filename) { |info| info.bitrate.should == 128 }
  end
  
  it "should detect that the sample file is encoded as joint stereo" do
    Mp3Info.open(@mp3_filename) { |info| info.channel_mode.should == "Joint stereo" }
  end
  
  it "should detect that the sample file has a sample rate of 44.1kHz" do
    Mp3Info.open(@mp3_filename) { |info| info.samplerate.should == 44_100 }
  end
  
  it "should detect that the sample file is not error-protected" do
    Mp3Info.open(@mp3_filename) { |info| info.error_protection.should be_false }
  end
  
  it "should detect that the sample file has a duration of 0.1305625 seconds" do
    Mp3Info.open(@mp3_filename) { |info| info.length.should == 0.1305625 }
  end
  
  it "should correctly format the summary info for the sample file" do
    Mp3Info.open(@mp3_filename) { |info| info.to_s.should == "Time: 0:00        MPEG1.0 Layer 3           [ 128kbps @ 44.1kHz - Joint stereo ]" }
  end
end

describe Mp3Info, 'when working with its "universal" tag' do
  include Mp3InfoHelper
  
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  it "should be able to repeatably update the universal tag without corrupting it" do
    5.times do
      tag = {"title" => Mp3InfoHelper::TEST_TITLE}
      Mp3Info.open(@mp3_filename) do |mp3|
        tag.each { |k,v| mp3.tag[k] = v }
      end
      
      Mp3Info.open(@mp3_filename) { |m| m.tag }.should == tag
    end
  end
  
  it "should be able to store and retrieve shared information backed by an ID3v2 tag" do
    tag = {}
    %w{comments title artist album}.each { |k| tag[k] = k }
    tag["tracknum"] = 34
    
    Mp3Info.open(@mp3_filename) do |mp3|
      tag.each { |k,v| mp3.tag[k] = v }
    end
    
    w = Mp3Info.open(@mp3_filename) { |m| m.tag }
    w.delete("genre")
    w.delete("genre_s")
    w.should == tag
  end
end

describe Mp3Info, "when working with ID3v1 tags" do
  include Mp3InfoHelper

  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should be able to add the tag without error" do
    lambda { Mp3Info.open(@mp3_filename) { |info| info.tag1 = sample_id3v1_tag } }.should_not raise_error(Mp3InfoError)
    Mp3Info.hastag1?(@mp3_filename).should be_true
  end
  
  it "should be able to add and remove the tag without error" do
    lambda { Mp3Info.open(@mp3_filename) { |info| info.tag1 = sample_id3v1_tag } }.should_not raise_error(Mp3InfoError)
    Mp3Info.hastag1?(@mp3_filename).should be_true
    lambda { Mp3Info.removetag1(@mp3_filename) }.should_not raise_error(Mp3InfoError)
    Mp3Info.hastag1?(@mp3_filename).should be_false
  end

  it "should be able to add a tag and then remove it from within the open() block" do
    lambda { Mp3Info.open(@mp3_filename) { |info| info.tag1 = sample_id3v1_tag } }.should_not raise_error(Mp3InfoError)
    Mp3Info.hastag1?(@mp3_filename).should be_true
    lambda { Mp3Info.open(@mp3_filename) { |info| info.removetag1 } }.should_not raise_error(IOError, "closed stream")
    Mp3Info.hastag1?(@mp3_filename).should be_false
  end
  
  it "should be able to add and then find a ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.hastag1?(@mp3_filename).should be_true
  end
  
  it "should correctly identify the tag as ID3v1.0 and not ID3v1.1" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1.version.should == Mp3Info::ID3_V_1_0
  end
  
  it "should be able to find the title from a ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['title'].should == Mp3InfoHelper::TEST_TITLE
  end
  
  it "should be able to find the artist in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['artist'].should == Mp3InfoHelper::TEST_ARTIST
  end
  
  it "should be able to find the album in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['album'].should == Mp3InfoHelper::TEST_ALBUM
  end
  
  it "should be able to find the comments in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['comments'].should == Mp3InfoHelper::TEST_COMMENT
  end
  
  it "should be able to find the genre ID in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['genre'].should == Mp3InfoHelper::TEST_GENRE_ID
  end
  
  it "should be able to find the genre name in an ID3v1.0 tag" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['genre_s'].should == Mp3InfoHelper::TEST_GENRE_NAME
  end
  
  it "should not be able to find the track number in an ID3v1.0 tag, because the tag doesn't contain it" do
    create_valid_id3_1_0_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['tracknum'].should == nil
  end
  
  it "should be able to add and then find an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.hastag1?(@mp3_filename).should be_true
  end
  
  it "should correctly identify the tag as ID3v1.1 and not ID3v1.0" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1.version.should == Mp3Info::ID3_V_1_1
  end
  
  it "should be able to find the title in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['title'].should == Mp3InfoHelper::TEST_TITLE
  end
  
  it "should be able to find the artist in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['artist'].should == Mp3InfoHelper::TEST_ARTIST
  end
  
  it "should be able to find the album in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['album'].should == Mp3InfoHelper::TEST_ALBUM
  end
  
  it "should be able to find the comments in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['comments'].should == Mp3InfoHelper::TEST_COMMENT
  end
  
  it "should be able to find the genre ID in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['genre'].should == Mp3InfoHelper::TEST_GENRE_ID
  end
  
  it "should be able to find the genre name in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['genre_s'].should == Mp3InfoHelper::TEST_GENRE_NAME
  end
  
  it "should be able to find the track number in an ID3v1.1 tag" do
    create_valid_id3_1_1_file(@mp3_filename)
    
    Mp3Info.new(@mp3_filename).tag1['tracknum'].should == Mp3InfoHelper::TEST_TRACK_NUMBER
  end
  
  it "should correctly name an invalid genre ID 'Unknown'" do
    tag = sample_id3v1_tag
    tag['genre'] = Mp3InfoHelper::INVALID_GENRE_ID
    
    Mp3Info.open(@mp3_filename) { |info| info.tag1 = tag }
    Mp3Info.new(@mp3_filename).tag1['genre_s'].should == "Unknown"
  end
end

describe Mp3Info, "when working with ID3v2 tags" do
  include Mp3InfoHelper
  
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @trivial_id3v2_tag = {"TIT2" => ID3V24::Frame.create_frame('TIT2', "sdfqdsf")}
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should be able to add the tag without error" do
    finish_tag = {}
    lambda { finish_tag = update_id3_2_tag(@mp3_filename, @trivial_id3v2_tag) }.should_not raise_error(Mp3InfoError)
    finish_tag.should == @trivial_id3v2_tag
  end
  
  it "should be able to add and remove the tag without error" do
    update_id3_2_tag(@mp3_filename, @trivial_id3v2_tag)
    
    Mp3Info.hastag2?(@mp3_filename).should be_true
    Mp3Info.removetag2(@mp3_filename)
    Mp3Info.hastag2?(@mp3_filename).should be_false
  end
  
  it "should be able to add the tag and then remove it from within the open() block" do
    update_id3_2_tag(@mp3_filename, @trivial_id3v2_tag)
    
    Mp3Info.hastag2?(@mp3_filename).should be_true
    lambda { Mp3Info.open(@mp3_filename) { |info| info.removetag2 } }.should_not raise_error(Mp3InfoError)
    Mp3Info.hastag2?(@mp3_filename).should be_false
  end
  
  it "should be able to discover the version of the ID3v2 tag written to disk" do
    update_id3_2_tag(@mp3_filename, sample_id3v2_tag).version.should == "2.4.0"
  end
  
  it "should be able to treat each ID3v2 frame as a directly-accessible attribute of the tag" do
    tag = {
      "TIT2" => ID3V24::Frame.create_frame("TIT2", "tit2"),
      "TPE1" => ID3V24::Frame.create_frame("TPE1", "tpe1")
      }
    
    Mp3Info.open(@mp3_filename) do |mp3|
      tag.each do |k, v|
        mp3.tag2.send("#{k}=".to_sym, v)
      end
      
      mp3.tag2.should == tag
    end
  end
  
  # test the tag with the "id3v2" program -- you'll need a version of id3lib
  # that's been patched to work with ID3v2 2.4.0 tags, which probably means
  # a version of id3lib above 3.8.3
  it "should produce results equivalent to those produced by the id3v2 utility" do
    written_tag = update_id3_2_tag(@mp3_filename, sample_id3v2_tag)
    written_tag.should == sample_id3v2_tag
    
    test_against_id3v2_prog(written_tag).should == prettify_tag(written_tag)
  end
  
  it "should handle storing and retrieving tags containing arbitrary binary data" do
    10.times do
      tag = {}
      ["PRIV", "APIC"].each do |k|
        tag[k] = ID3V24::Frame.create_frame(k, random_string(50))
      end
      
      update_id3_2_tag(@mp3_filename, tag).should == tag
    end
  end
  
  it "should handle storing tags via the tag update mechanism" do
    tag = {}
    ["PRIV", "APIC"].each do |k|
      tag[k] = ID3V24::Frame.create_frame(k, random_string(50))
    end
    
    Mp3Info.open(@mp3_filename) do |mp3|
      # before update
      mp3.tag2.should == {}
      mp3.tag2.update(tag)
    end
    
    # after update has been saved
    Mp3Info.open(@mp3_filename) { |m| m.tag2 }.should == tag
  end
  
  it "should read an ID3v2 tag from a truncated MP3 file" do
    lambda { mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'./sample-metadata/zovietfrance/Popular Soviet Songs And Youth Music disc 3/zovietfrance - Popular Soviet Songs And Youth Music - 08 - Shewel.mp3')) }.should_not raise_error
  end
  
  it "should still read the tag from a truncated MP3 file" do
    lambda { mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'./sample-metadata/230-unicode.tag')) }.should_not raise_error
  end
  
  it "should make it easy to casually use ID3v2 tags" do
    Mp3Info.open(@mp3_filename) do |mp3|
      mp3.tag2.WCOM = "http://www.riaa.org/"
      mp3.tag2.TXXX = "A sample comment"
    end
    
    mp3 = Mp3Info.new(@mp3_filename)
    saved_tag = mp3.tag2
    
    saved_tag.WCOM.value.should == "http://www.riaa.org/"
    saved_tag.TXXX.value.should == "A sample comment"
  end
end

describe ID3V24::Frame, "when working with individual frames" do
  include Mp3InfoHelper
  
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @trivial_id3v2_tag = {"TIT2" => ID3V24::Frame.create_frame('TIT2', "sdfqdsf")}
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should create a raw frame when given an unknown frame ID" do
    ID3V24::Frame.create_frame('XXXX', 0).class.should == ID3V24::Frame
  end
  
  it "should gracefully handle unknown frame types" do
    crud = random_string(64)
    tag = { "XNXT" => ID3V24::Frame.create_frame("XNXT", crud) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    saved_tag.XNXT.class.should == ID3V24::Frame
    saved_tag.XNXT.value.should == crud
    saved_tag.XNXT.to_s_pretty.should == crud.inspect
    saved_tag.XNXT.frame_info.should == "No description available for frame type 'XNXT'."
  end
  
  it "should create a generic text frame when given an unknown Txxx frame ID" do
    ID3V24::Frame.create_frame('TPOS', '1/14').class.should == ID3V24::TextFrame
  end

  it "should create a link frame when given an unknown Wxxx frame ID" do
    ID3V24::Frame.create_frame('WOAR', 'http://www.dresdendolls.com/').class.should == ID3V24::LinkFrame
  end

  it "should create a custom frame type when given a custom ID (TCON)" do
    ID3V24::Frame.create_frame('TCON', 'Experimetal').class.should == ID3V24::TCONFrame
  end
  
  it "should correctly retrieve the description for the conductor frame" do
    tag = { "TPE3" => ID3V24::Frame.create_frame("TPE3", "Leopold Stokowski") }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    saved_tag.TPE3.class.should == ID3V24::TextFrame
    saved_tag.TPE3.value.should == "Leopold Stokowski"
    saved_tag.TPE3.to_s_pretty.should == "Leopold Stokowski"
    saved_tag.TPE3.frame_info.should ==  "The 'Conductor' frame is used for the name of the conductor."
  end
  
  it "should correctly retrieve the description for the original audio link frame" do
    tag = { "WOAF" => ID3V24::Frame.create_frame("WOAF", "http://example.com/audio.html") }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    saved_tag.WOAF.class.should == ID3V24::LinkFrame
    saved_tag.WOAF.value.should == "http://example.com/audio.html"
    saved_tag.WOAF.to_s_pretty.should == "URL: http://example.com/audio.html"
    saved_tag.WOAF.frame_info.should == "The 'Official audio file webpage' frame is a URL pointing at a file specific webpage."
  end
  
  it "should correctly store lots of binary data in a frame" do
    tag = {"APIC" => ID3V24::Frame.create_frame("APIC", random_string(2 ** 16)) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    saved_tag.APIC.value.size.should == (2 ** 16)
    saved_tag.should == tag
  end
end

describe ID3V24::Frame, "when dealing with the various frame encoding types" do
  include Mp3InfoHelper
  
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should correctly handle ISO 8859-1 text" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Junior Citizen (lé Freak!)")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:iso]
    tag = { "TIT2" => tit2 }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    # ID3V24::TextFrame::ENCODING[:iso] => 0
    saved_tag.TIT2.encoding.should == 0
    saved_tag.TIT2.encoding.should == ID3V24::TextFrame::ENCODING[:iso]
    saved_tag.TIT2.value.should == "Junior Citizen (lé Freak!)"
  end
  
  it "should correctly handle UTF-16 Unicode text with a byte-order mark" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:utf16]
    tag = { "TIT2" => tit2 }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    # ID3V24::TextFrame::ENCODING[:utf16] => 1
    saved_tag.TIT2.encoding.should == 1
    saved_tag.TIT2.encoding.should == ID3V24::TextFrame::ENCODING[:utf16]
    saved_tag.TIT2.value.should == "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈"
  end
  
  it "should correctly handle big-endian UTF-16 Unicode text" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:utf16be]
    tag = { "TIT2" => tit2 }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    # ID3V24::TextFrame::ENCODING[:utf16be] => 2
    saved_tag.TIT2.encoding.should == 2
    saved_tag.TIT2.encoding.should == ID3V24::TextFrame::ENCODING[:utf16be]
    saved_tag.TIT2.value.should == "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈"
  end
  
  it "should correctly handle UTF-8 Unicode text" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:utf8]
    tag = { "TIT2" => tit2 }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    # ID3V24::TextFrame::ENCODING[:utf8] => 3
    saved_tag.TIT2.encoding.should == 3
    saved_tag.TIT2.encoding.should == ID3V24::TextFrame::ENCODING[:utf8]
    saved_tag.TIT2.value.should == "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈"
  end
  
  it "should raise a conversion error when trying to save Unicode text in an ISO 8859-1-encoded frame" do
    tit2 = ID3V24::Frame.create_frame("TIT2", "Sviatoslav Richter: Святослав Теофилович Рихтер Kana:  香奈")
    tit2.encoding = ID3V24::TextFrame::ENCODING[:iso]
    tag = { "TIT2" => tit2 }
    lambda { update_id3_2_tag(@mp3_filename, tag) }.should raise_error(Iconv::IllegalSequence)
  end
end

describe ID3V24::APICFrame, "when creating a new APIC (picture) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)

    @random_data = random_string(128)
    tag = { "APIC" => ID3V24::Frame.create_frame("APIC", @random_data) }
    @saved_frame = update_id3_2_tag(@mp3_filename, tag).APIC
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::APICFrame
  end
  
  it "should choose a default encoding for the description of the image of UTF-16" do
    @saved_frame.encoding.should == ID3V24::TextFrame::ENCODING[:utf16]
  end
  
  it "should default to having a blank description" do
    @saved_frame.description.should == "cover image"
  end
  
  it "should default to having an image type of 'image/jpeg'" do
    @saved_frame.mime_type.should == 'image/jpeg'
  end
  
  it "should default to a picture type of 3 ('Cover (front)')" do
    @saved_frame.picture_type.should == "\x03"
  end
  
  it "should default to a picture type name of 'Cover (front)'" do
    @saved_frame.picture_type_name.should == "Cover (front)"
  end
  
  it "should safely retrieve the picture data" do
    @saved_frame.value.should == @random_data
  end
  
  it "should have a consistent pretty description with default values set" do
    @saved_frame.to_s_pretty.should == "Attached Picture (cover image) of image type image/jpeg and class Cover (front) of size 128"
  end
end

describe ID3V24::COMMFrame, "when creating a new COMM (comment) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @comment_text = "This is a sample comment."
    tag = { "COMM" => ID3V24::Frame.create_frame("COMM", @comment_text) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag.COMM
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::COMMFrame
  end
  
  it "should choose a default encoding for the description of the image of UTF-16" do
    @saved_frame.encoding.should == ID3V24::TextFrame::ENCODING[:utf16]
  end
  
  it "should have a default description of 'Mp3Info Comment'" do
    @saved_frame.description.should == 'Mp3Info Comment'
  end
  
  it "should default to being in English (sorry, non-English-speaking world)" do
    @saved_frame.language.should == 'eng'
  end
  
  it "should default having a pretty format identical to id3v2's" do
    @saved_frame.to_s_pretty.should == "(Mp3Info Comment)[eng]: This is a sample comment."
  end
  
  it "should retrieve the stored comment value correctly" do
    @saved_frame.value.should == @comment_text
  end
  
  it "should produce output identical to id3v2's when compared" do
    test_against_id3v2_prog(@saved_tag).should == prettify_tag(@saved_tag)
  end
end

describe ID3V24::COMMFrame, "when creating a new COMM (comment) frame customized for ::AOAIOXXYSZ::" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @comment_text = "Track 5"
    comm = ID3V24::Frame.create_frame("COMM", @comment_text)
    comm.description = '::AOAIOXXYSZ:: Info'
    tag = { "COMM" => comm }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag.COMM
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::COMMFrame
  end
  
  it "should choose a default encoding for the description of the image of UTF-16" do
    @saved_frame.encoding.should == ID3V24::TextFrame::ENCODING[:utf16]
  end
  
  it "should describe itself as an '::AOAIOXXYSZ:: Info' frame" do
    @saved_frame.description.should == '::AOAIOXXYSZ:: Info'
  end
  
  it "should default to being in English (sorry, non-English-speaking world)" do
    @saved_frame.language.should == 'eng'
  end
  
  it "should default having a pretty format identical to id3v2's" do
    @saved_frame.to_s_pretty.should == "(::AOAIOXXYSZ:: Info)[eng]: Track 5"
  end
  
  it "should retrieve the stored comment value correctly" do
    @saved_frame.value.should == @comment_text
  end
  
  it "should produce output identical to id3v2's when compared" do
    test_against_id3v2_prog(@saved_tag).should == prettify_tag(@saved_tag)
  end
end

describe ID3V24::COMMFrame, "when creating a new COMM (comment) frame containing Russian (and other Unicode)" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @comment_text = "Здравствуйте dïáçrìtícs!"
    comm = ID3V24::Frame.create_frame("COMM", @comment_text)
    comm.language = 'rus'
    tag = { "COMM" => comm }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag.COMM
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should be in Russian" do
    @saved_frame.language.should == 'rus'
  end
  
  it "should retrieve the stored comment value correctly" do
    @saved_frame.value.should == @comment_text
  end
  
  it "should default having a pretty format identical to id3v2's, if id3v2 actually supported Unicode" do
    @saved_frame.to_s_pretty.should == "(Mp3Info Comment)[rus]: Здравствуйте dïáçrìtícs!"
  end
end

describe ID3V24::PRIVFrame, "when creating a new PRIV (private data) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    # Base64 encode the data because for this test I want to test the defaults, not binary storage
    @random_data = Base64::encode64(random_string(128))
    tag = { "PRIV" => ID3V24::Frame.create_frame("PRIV", @random_data) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag.PRIV
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::PRIVFrame
  end
  
  it "should default to being owned by me (sure, why not?)" do
    @saved_frame.owner.should == 'mailto:ogd@aoaioxxysz.net'
  end
  
  it "should retrieve the stored private data correctly" do
    @saved_frame.value.should == @random_data
  end
  
  it "should produce a useful pretty-printed representation" do
    @saved_frame.to_s_pretty.should == "PRIVATE DATA (from mailto:ogd@aoaioxxysz.net) [#{@random_data.inspect}]"
  end
end

describe ID3V24::TCMPFrame, "when creating a new TCMP (iTunes-specific compilation flag) frame" do
  include Mp3InfoHelper
  
  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end
  
  after do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should correctly indicate when the track is part of a compilation" do
    tag = { "TCMP" => ID3V24::Frame.create_frame("TCMP", true) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    saved_tag.TCMP.class.should == ID3V24::TCMPFrame
    saved_tag.TCMP.value.should == true
    saved_tag.TCMP.to_s_pretty.should == "This track is part of a compilation."
  end
  
  it "should correctly indicate when the track is not part of a compilation" do
    tag = { "TCMP" => ID3V24::Frame.create_frame("TCMP", false) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    
    saved_tag.TCMP.class.should == ID3V24::TCMPFrame
    saved_tag.TCMP.value.should == false
    saved_tag.TCMP.to_s_pretty.should == "This track is not part of a compilation."
  end
end

describe ID3V24::TCONFrame, "when creating a new TCON (genre) frame with a genre that corresponds to an ID3v1 genre ID" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @genre_name = "Jungle"
    tag = { "TCON" => ID3V24::Frame.create_frame("TCON", @genre_name) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag.TCON
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::TCONFrame
  end
  
  it "should retrieve 'Jungle' as the bare genre name" do
    @saved_frame.value.should == @genre_name
  end
  
  it "should find the numeric genre ID for 'Jungle'" do
    @saved_frame.genre_code.should == 63
  end
  
  it "should pretty-print the genre name id3v2 style, as 'Name (id)'" do
    @saved_frame.to_s_pretty.should == "Jungle (63)"
  end
end

describe ID3V24::TCONFrame, "when creating a new TCON (genre) frame with a genre with no genre ID" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @genre_name = "Experimental"
    tag = { "TCON" => ID3V24::Frame.create_frame("TCON", @genre_name) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag.TCON
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::TCONFrame
  end
  
  it "should retrieve 'Experimental' as the bare genre name" do
    @saved_frame.value.should == @genre_name
  end
  
  it "should fail to find a numeric genre ID for 'Experimental' and use 255 instead" do
    @saved_frame.genre_code.should == 255
  end
  
  it "should pretty-print the genre name id3v2 style, as 'Name (255)'" do
    @saved_frame.to_s_pretty.should == "Experimental (255)"
  end
end

describe ID3V24::TXXXFrame, "when creating a new TXXX (user-defined text) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @user_text = "Here is some random user-defined text."
    tag = { "TXXX" => ID3V24::Frame.create_frame("TXXX", @user_text) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag.TXXX
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::TXXXFrame
  end
  
  it "should be saved as UTF-16 Unicode text with a byte-order mark by default" do
    @saved_frame.encoding.should == ID3V24::TextFrame::ENCODING[:utf16]
  end
  
  it "should have 'Mp3Info Comment' as its default description (this should be overridden in practice)" do
    @saved_frame.description.should == 'Mp3Info Comment'
  end
  
  it "should safely retrieve its value" do
    @saved_frame.value.should == @user_text
  end
  
  it "should pretty-print in the style of id3v2" do
    @saved_frame.to_s_pretty.should == "(Mp3Info Comment) : Here is some random user-defined text."
  end
end

describe ID3V24::WXXXFrame, "when creating a new WXXX (user-defined link) frame with defaults" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @user_link = "http://www.yourmom.gov"
    tag = { "WXXX" => ID3V24::Frame.create_frame("WXXX", @user_link) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag.WXXX
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::WXXXFrame
  end
  
  it "should have a description encoded as UTF-16 Unicode text with a byte-order mark by default" do
    @saved_frame.encoding.should == ID3V24::TextFrame::ENCODING[:utf16]
  end
  
  it "should have 'Mp3Info User Link' as its default description (this should be overridden in practice)" do
    @saved_frame.description.should == 'Mp3Info User Link'
  end
  
  it "should safely retrieve its value" do
    @saved_frame.value.should == @user_link
  end
  
  it "should pretty-print in the style of id3v2" do
    @saved_frame.to_s_pretty.should == "(Mp3Info User Link) : http://www.yourmom.gov"
  end
end

describe ID3V24::UFIDFrame, "when creating a new UFID (unique file identifier) frame" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @ufid = "2451-4235-af32a3-1312"
    tag = { "UFID" => ID3V24::Frame.create_frame("UFID", @ufid) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag.UFID
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::UFIDFrame
  end
  
  it "has no default namespace, but uses 'http://www.id3.org/dummy/ufid.html' instead" do
    @saved_frame.namespace.should == "http://www.id3.org/dummy/ufid.html"
  end
  
  it "should retrieve the stored ID unmolested" do
    @saved_frame.value.should == @ufid
  end
  
  it "should pretty-print the unique ID as namespace: \"ID\"" do
    @saved_frame.to_s_pretty.should == 'http://www.id3.org/dummy/ufid.html: "2451-4235-af32a3-1312"'
  end
end

describe ID3V24::XDORFrame, "when dealing with the iTunes and ID3v2.3-specific XDOR (date of release) frame" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @release_date = Time.gm(1993, 3, 8)
    tag = { "XDOR" => ID3V24::Frame.create_frame("XDOR", @release_date) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag.XDOR
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should convert the release date to a known value captured from an iTunes-created file" do
    xdor = ID3V24::Frame.create_frame("XDOR", Time.gm(1993, 3, 8))
    xdor.to_s.should == "\001\376\377\0001\0009\0009\0003\000-\0000\0003\000-\0000\0008\000\000"
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::XDORFrame
  end
  
  it "should reconstitute the release date properly" do
    @saved_frame.value.should == @release_date
  end
  
  it "should pretty-print the release date as an RFC-compliant date" do
    @saved_frame.to_s_pretty.should == "Release date: Mon Mar 08 00:00:00 UTC 1993"
  end
end

describe ID3V24::XSOPFrame, "when dealing with the iTunes and ID3v2.3-specific XSOP (artist sort order) frame" do
  include Mp3InfoHelper
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @artist_the = "Clash, The"
    tag = { "XSOP" => ID3V24::Frame.create_frame("XSOP", @artist_the) }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag.XSOP
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    @saved_frame.class.should == ID3V24::XSOPFrame
  end
  
  it "should reconstitute the artist sort name properly" do
    @saved_frame.value.should == @artist_the
  end
  
  it "should pretty-print the artist sort name identically to printing its raw value" do
    @saved_frame.to_s_pretty.should == @artist_the
  end
end

describe ID3V24::Frame, "when reading examples of real MP3 files" do
  it "should read ID3v2.2 tags correctly" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'sample-metadata/Keith Fullerton Whitman/Multiples/Stereo Music For Hi-Hat.mp3'))
    tag2 = mp3.tag2
    
    tag2.TP1.value.should == 'Keith Fullerton Whitman'
    tag2.TCM.value.should == 'Keith Fullerton Whitman'
    tag2.TAL.value.should == 'Multiples'
    tag2.TCO.value.should == 'Ambient'
    tag2.TCO.genre_code.should == 26
    tag2.TCO.to_s_pretty.should == 'Ambient (26)'
    tag2.TYE.value.should == '2005'
    tag2.TRK.value.should == '1/8'
  end
  
  it "should read image frames from ID3v2.3 tags without mangling them" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'sample-metadata/RAC/Double Jointed/03 - RAC - Nine.mp3'))
    tag2 = mp3.tag2
    
    mp3.tag2_len.should == 7302
    tag2.APIC.raw_size.should == 5026
    Digest::SHA1.hexdigest(tag2.APIC.value).should == '6902c6f4f81838208dd26f88274bf7444f7798a7'
    tag2.APIC.value.size.should == 5013
  end
  
  it "should correctly read frame lengths from ID3v2.4 tags even if the lengths aren't encoded syncsafe" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'sample-metadata/Jurgen Paape/Speicher 47/01 Fruity Loops 1.mp3'))
    tag2 = mp3.tag2
    
    mp3.tag2_len.should == 35_092
    tag2.APIC.raw_size.should == 34_698
    tag2.APIC.value.size.should == 34_685
    tag2.COMM.first.language.should == 'eng'
    tag2.COMM.first.value.should == '<<in Love With The Music>>'
    tag2.WXXX.value.should == 'http://www.kompakt-net.com'
    tag2.TPE1.value.should == 'Jürgen Paape'
    tag2.TIT1.value.should == 'Kompakt Extra 47'
    tag2.TIT2.value.should == 'Fruity Loops 1'
    tag2.TDRC.value.should == '2007'
    tag2.TLAN.value.should == 'German'
    tag2.TENC.value.should == 'LAME 3.96'
    tag2.TCON.value.should == 'Techno'
  end
  
  it "should correctly find all the repeated frames, no matter how many are in a tag" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),"sample-metadata/Master Fool/Skilligans Island/Master Fool - Skilligan's Island - 14 - I Still Live With My Moms.mp3"))
    tag2 = mp3.tag2
    
    # COMM (Comments): ()[XXX]: RIPT with GRIP
    # COMM (Comments): ()[]: Created by Grip
    # COMM (Comments): (ID3v1 Comment)[XXX]: RIPT with GRIP
    # TALB (Album/Movie/Show title): Skilligan's Island
    # TALB (Album/Movie/Show title): Skilligan's Island
    # TCON (Content type): Indie Rap (255)
    # TIT2 (Title/songname/content description): I Still Live With My Moms
    # TIT2 (Title/songname/content description): I Still Live With My Moms
    # TPE1 (Lead performer(s)/Soloist(s)): Master Fool
    # TPE1 (Lead performer(s)/Soloist(s)): Master Fool
    # TRCK (Track number/Position in set): 14
    # TRCK (Track number/Position in set): 14
    # TYER (Year): 2002
    # TYER (Year): 2002
    
    tag2.COMM.size.should == 3
    tag2.COMM.detect { |frame|
      'XXX' == frame.language && 
      '' == frame.description &&
      'RIPT with GRIP' == frame.value
    }.should be_true
    
    tag2.COMM.detect { |frame|
      "\000\000\000" == frame.language && 
      '' == frame.description &&
      'Created by Grip' == frame.value
    }.should be_true
    
    tag2.COMM.detect { |frame|
      'XXX' == frame.language && 
      'ID3v1 Comment' == frame.description &&
      'RIPT with GRIP' == frame.value
    }.should be_true
    
    tag2.TALB.size.should == 2
    tag2.TALB.detect { |frame|
      'Skilligan\'s Island' == frame.value
    }.should be_true
    
    tag2.TIT2.size.should == 2
    tag2.TIT2.detect { |frame|
      'I Still Live With My Moms' == frame.value
    }.should be_true
    
    tag2.TPE1.size.should == 2
    tag2.TPE1.detect { |frame|
      'Master Fool' == frame.value
    }.should be_true
    
    tag2.TRCK.size.should == 2
    tag2.TRCK.detect { |frame|
      '14' == frame.value
    }.should be_true
    
    tag2.TYER.size.should == 2
    tag2.TYER.detect { |frame|
      '2002' == frame.value
    }.should be_true
  end
end