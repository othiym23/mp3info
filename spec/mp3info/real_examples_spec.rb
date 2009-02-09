$:.unshift("lib/")

require 'mp3info'

describe Mp3Info, "when working with real files" do
  it "should find all the same metadata eyeD3 does for a Keith Fullerton Whitman track" do
    mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../sample-metadata/Keith Fullerton Whitman/Multiples/Stereo Music For Hi-Hat.mp3'))
    
    mp3.has_mpeg_header?.should be_true
    mp3.mpeg_header.should_not be_nil
    mpeg_info = mp3.mpeg_header
    mpeg_info.version.should == 1.0
    mpeg_info.layer.should == 3
    mpeg_info.sample_rate.should == 44_100
    mpeg_info.bitrate.should == 128
    mpeg_info.mode.should == 'Joint stereo'
    mpeg_info.mode_extension.should == 0
    mpeg_info.error_protection.should be_false
    mpeg_info.original_stream?.should be_true
    mpeg_info.copyrighted_stream?.should be_false
    mpeg_info.private_stream?.should be_false
    mpeg_info.padded_stream?.should be_false
    mpeg_info.emphasis.should == MPEGHeader::EMPHASIS_NONE
    mpeg_info.frame_length.should == 417
    
    mp3.has_xing_header?.should be_true
    mp3.xing_header.should_not be_nil
    xing_info = mp3.xing_header
    xing_info.vbr?.should be_true
    xing_info.frames.should == 6493
    xing_info.bytes.should == 3_539_892
    xing_info.has_toc?.should be_true
    xing_info.quality.should == 57
  end
end