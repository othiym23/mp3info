require "mp3info"

describe Mp3Info, "when reading a set of excerpted MP3 files with TLEN tags set to 0" do
  it "should display a time of 0 wihout throwing errors for track 17" do
    @mp3 = Mp3Info.new(File.join(__dir__, "../../sample-metadata/mp3info-qa/04529116bca3c23601b06c1fda44c5904c2b9537.mp3"))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag["TLEN"]).not_to be_nil
    expect(@mp3.id3v2_tag["TLEN"].value.to_i).to eq(0)
    expect(@mp3.duration_string).to eq("0:00")
    expect(@mp3.id3v2_tag["TPE1"].value).to eq("Aphex Twin")
    expect(@mp3.id3v2_tag["TRCK"].value).to eq("17/26")
  end

  it "should display a time of 0 wihout throwing errors for track 18" do
    @mp3 = Mp3Info.new(File.join(__dir__, "../../sample-metadata/mp3info-qa/01ff478b2c203293e5aec1296a44742cc1f4d026.mp3"))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag["TLEN"]).not_to be_nil
    expect(@mp3.id3v2_tag["TLEN"].value.to_i).to eq(0)
    expect(@mp3.duration_string).to eq("0:00")
    expect(@mp3.id3v2_tag["TPE1"].value).to eq("Aphex Twin")
    expect(@mp3.id3v2_tag["TRCK"].value).to eq("18/26")
  end

  it "should display a time of 0 wihout throwing errors for track 25" do
    @mp3 = Mp3Info.new(File.join(__dir__, "../../sample-metadata/mp3info-qa/169e8b2183a3c7b4873ba2a23254092677fdeed4.mp3"))
    expect(@mp3.has_id3v2_tag?).to be true
    expect(@mp3.id3v2_tag["TLEN"]).not_to be_nil
    expect(@mp3.id3v2_tag["TLEN"].value.to_i).to eq(0)
    expect(@mp3.duration_string).to eq("0:00")
    expect(@mp3.id3v2_tag["TPE1"].value).to eq("Aphex Twin")
    expect(@mp3.id3v2_tag["TRCK"].value).to eq("25/26")
  end
end
