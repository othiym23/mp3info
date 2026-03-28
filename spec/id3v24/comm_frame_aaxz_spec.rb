# encoding: utf-8

describe ID3V24::COMMFrame, "when creating a new COMM (comment) frame customized for ::AOAIOXXYSZ::" do
  
  before :all do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
    
    @comment_text = "Ευφροσυνη"
    comm = ID3V24::Frame.create_frame("COMM", @comment_text)
    comm.description = '::AOAIOXXYSZ:: Info'
    tag = { "COMM" => comm }
    @saved_tag = update_id3_2_tag(@mp3_filename, tag)
    @saved_frame = @saved_tag['COMM']
  end
  
  after :all do
    FileUtils.rm_f(@mp3_filename)
  end
  
  it "should have been reconstituted as the correct class" do
    expect(@saved_frame.class).to eq(ID3V24::COMMFrame)
  end
  
  it "should choose a default encoding for the comment (and its description) of UTF-8" do
    expect(@saved_frame.encoding).to eq(ID3V24::TextFrame::ENCODING[:utf8])
  end
  
  it "should describe itself as an '::AOAIOXXYSZ:: Info' frame" do
    expect(@saved_frame.description).to eq('::AOAIOXXYSZ:: Info')
  end
  
  it "should default to being in English (sorry, non-English-speaking world)" do
    expect(@saved_frame.language).to eq('eng')
  end
  
  it "should retrieve the stored comment value correctly" do
    expect(@saved_frame.value).to eq(@comment_text)
  end
end
