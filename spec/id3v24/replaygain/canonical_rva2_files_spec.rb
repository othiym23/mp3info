# encoding: utf-8
$:.unshift("lib/")

require 'mp3info'

describe Mp3Info, "when reading a set of files with RVA2 tags with verified replaygain values" do
  it "should find the correct gain values for the original file" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../../sample-metadata/Replay Gain RVA2/00-RVA2-orig.mp3'))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag['RVA2']).to be_nil
  end
  
  it "should find the correct gain values for a file softened by 2 dB" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../../sample-metadata/Replay Gain RVA2/01-FC00-2dBsofter-trackonly.mp3'))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag['RVA2']).not_to be_nil
    expect(@mp3.id3v2_tag['RVA2'].identifier).to eq('track')
    expect(@mp3.id3v2_tag['RVA2'].adjustments.size).to eq(1)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].adjustment).to eq(-2.0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain_bit_width).to eq(0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain).to eq(0)
  end
  
  it "should find the correct gain values for a file softened by 4 dB" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../../sample-metadata/Replay Gain RVA2/02-F800-4dBsofter-trackonly.mp3'))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag['RVA2']).not_to be_nil
    expect(@mp3.id3v2_tag['RVA2'].identifier).to eq('track')
    expect(@mp3.id3v2_tag['RVA2'].adjustments.size).to eq(1)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].adjustment).to eq(-4.0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain_bit_width).to eq(0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain).to eq(0)
  end
  
  it "should find the correct gain values for a file softened by 11 dB" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../../sample-metadata/Replay Gain RVA2/03-EA00-8dBsofter-trackonly.mp3'))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag['RVA2']).not_to be_nil
    expect(@mp3.id3v2_tag['RVA2'].identifier).to eq('track')
    expect(@mp3.id3v2_tag['RVA2'].adjustments.size).to eq(1)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].adjustment).to eq(-11.0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain_bit_width).to eq(0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain).to eq(0)
  end
  
  it "should find the correct gain values for a file softened by 18 dB" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../../sample-metadata/Replay Gain RVA2/04-DC00-12dBsofter-trackonly.mp3'))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag['RVA2']).not_to be_nil
    expect(@mp3.id3v2_tag['RVA2'].identifier).to eq('track')
    expect(@mp3.id3v2_tag['RVA2'].adjustments.size).to eq(1)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].adjustment).to eq(-18.0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain_bit_width).to eq(0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain).to eq(0)
  end
  
  it "should find the correct gain values for a file softened by 25 dB" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../../sample-metadata/Replay Gain RVA2/05-CE00-16dBsofter-trackonly.mp3'))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag['RVA2']).not_to be_nil
    expect(@mp3.id3v2_tag['RVA2'].identifier).to eq('track')
    expect(@mp3.id3v2_tag['RVA2'].adjustments.size).to eq(1)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].adjustment).to eq(-25.0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain_bit_width).to eq(0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain).to eq(0)
  end
  
  it "should find the correct gain values for a file emboldened by 2 dB" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../../sample-metadata/Replay Gain RVA2/07-0400-2dBlouder-trackonly.mp3'))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag['RVA2']).not_to be_nil
    expect(@mp3.id3v2_tag['RVA2'].identifier).to eq('track')
    expect(@mp3.id3v2_tag['RVA2'].adjustments.size).to eq(1)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].adjustment).to eq(2.0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain_bit_width).to eq(16)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain).to eq(6553)
  end
  
  it "should find the correct gain values for a file emboldened by 4 dB" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../../sample-metadata/Replay Gain RVA2/08-0800-4dBlouder-trackonly.mp3'))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag['RVA2']).not_to be_nil
    expect(@mp3.id3v2_tag['RVA2'].identifier).to eq('track')
    expect(@mp3.id3v2_tag['RVA2'].adjustments.size).to eq(1)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].adjustment).to eq(4.0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain_bit_width).to eq(16)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain).to eq(6553)
  end
  
  it "should find the correct gain values for a file emboldened by 8 dB" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../../sample-metadata/Replay Gain RVA2/09-1000-8dBlouder-trackonly.mp3'))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag['RVA2']).not_to be_nil
    expect(@mp3.id3v2_tag['RVA2'].identifier).to eq('track')
    expect(@mp3.id3v2_tag['RVA2'].adjustments.size).to eq(1)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].adjustment).to eq(8.0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain_bit_width).to eq(16)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain).to eq(6553)
  end
  
  it "should find the correct gain values for a file emboldened by 12 dB" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../../sample-metadata/Replay Gain RVA2/09-1800-12dBlouder-trackonly.mp3'))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag['RVA2']).not_to be_nil
    expect(@mp3.id3v2_tag['RVA2'].identifier).to eq('track')
    expect(@mp3.id3v2_tag['RVA2'].adjustments.size).to eq(1)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].adjustment).to eq(12.0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain_bit_width).to eq(16)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain).to eq(6553)
  end
  
  it "should find the correct gain values for a file emboldened by 12 dB" do
    @mp3 = Mp3Info.new(File.join(File.dirname(__FILE__),'../../../sample-metadata/Replay Gain RVA2/09-2000-16dBlouder-trackonly.mp3'))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag['RVA2']).not_to be_nil
    expect(@mp3.id3v2_tag['RVA2'].identifier).to eq('track')
    expect(@mp3.id3v2_tag['RVA2'].adjustments.size).to eq(1)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].adjustment).to eq(16.0)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain_bit_width).to eq(16)
    expect(@mp3.id3v2_tag['RVA2'].adjustments[0].peak_gain).to eq(6553)
  end
end
