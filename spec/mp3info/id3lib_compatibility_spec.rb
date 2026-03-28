# encoding: utf-8
$:.unshift("spec/")

require 'mp3info/mp3info_helper'

describe Mp3Info, "when comparing tagged files using the ID3lib-based command-line tool 'id3v2'" do
  include Mp3InfoHelper

  before do
    @mp3_filename = "test_mp3info.mp3"
    create_sample_mp3_file(@mp3_filename)
  end

  after do
    FileUtils.rm_f(@mp3_filename)
  end

  before :all do
    @id3v2_available = system('which id3v2 > /dev/null 2>&1')
  end

  # Write tags with id3v2 CLI (v2.3), read back with mp3info, verify interop
  it "should read basic text frames written by id3v2" do
    skip("id3v2 command not available") unless @id3v2_available

    system('id3v2', '-t', Mp3InfoHelper::TEST_TITLE, '-a', Mp3InfoHelper::TEST_ARTIST, '-A', Mp3InfoHelper::TEST_ALBUM,
           '-y', Mp3InfoHelper::TEST_YEAR, '-T', Mp3InfoHelper::TEST_TRACK_NUMBER.to_s, '-g', Mp3InfoHelper::TEST_GENRE_ID.to_s,
           @mp3_filename)

    mp3 = Mp3Info.new(@mp3_filename)
    expect(mp3.has_id3v2_tag?).to be true
    expect(mp3.id3v2_tag.version).to eq("2.3.0")
    expect(mp3.id3v2_tag['TIT2'].value).to eq(Mp3InfoHelper::TEST_TITLE)
    expect(mp3.id3v2_tag['TPE1'].value).to eq(Mp3InfoHelper::TEST_ARTIST)
    expect(mp3.id3v2_tag['TALB'].value).to eq(Mp3InfoHelper::TEST_ALBUM)
    expect(mp3.id3v2_tag['TYER'].value).to eq(Mp3InfoHelper::TEST_YEAR)
    expect(mp3.id3v2_tag['TRCK'].value).to eq(Mp3InfoHelper::TEST_TRACK_NUMBER.to_s)
    expect(mp3.id3v2_tag['TCON'].value).to eq(Mp3InfoHelper::TEST_GENRE_NAME)
  end

  it "should read comment frames written by id3v2" do
    skip("id3v2 command not available") unless @id3v2_available

    system('id3v2', '-c', Mp3InfoHelper::TEST_COMMENT, @mp3_filename)

    mp3 = Mp3Info.new(@mp3_filename)
    expect(mp3.has_id3v2_tag?).to be true
    expect(mp3.id3v2_tag['COMM']).not_to be_nil
    expect(mp3.id3v2_tag['COMM'].value).to eq(Mp3InfoHelper::TEST_COMMENT)
  end

  it "should read tags written by id3v2 after overwriting existing tags" do
    skip("id3v2 command not available") unless @id3v2_available

    # Write initial tags with id3v2
    system('id3v2', '-t', 'Original Title', '-a', 'Original Artist', @mp3_filename)
    # Overwrite with new tags
    system('id3v2', '-t', 'New Title', '-a', 'New Artist', @mp3_filename)

    mp3 = Mp3Info.new(@mp3_filename)
    expect(mp3.id3v2_tag['TIT2'].value).to eq('New Title')
    expect(mp3.id3v2_tag['TPE1'].value).to eq('New Artist')
  end

  # The non-pending tests that were already passing: keep them as-is
  it "should default having a pretty format identical to id3v2's" do
    comment_text = "This is a sample comment."
    tag = { "COMM" => ID3V24::Frame.create_frame("COMM", comment_text) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    expect(saved_tag['COMM'].to_s_pretty).to eq("(Mp3Info Comment)[eng]: This is a sample comment.")
  end

  it "should formate comment (COMM) frames identically to id3v2" do
    comment_text = "Ευφροσυνη"
    comm = ID3V24::Frame.create_frame("COMM", comment_text)
    comm.description = '::AOAIOXXYSZ:: Info'

    saved_tag = update_id3_2_tag(@mp3_filename, { "COMM" => comm })

    expect(saved_tag['COMM'].to_s_pretty).to eq("(::AOAIOXXYSZ:: Info)[eng]: Ευφροσυνη")
  end

  it "should default to having a pretty format identical to id3v2's, if id3v2 actually supported Unicode" do
    comment_text = "Здравствуйте dïáçrìtícs!"
    comm = ID3V24::Frame.create_frame("COMM", comment_text)
    comm.language = 'rus'

    saved_tag = update_id3_2_tag(@mp3_filename, { "COMM" => comm })
    saved_frame = saved_tag['COMM']

    expect(saved_frame.to_s_pretty).to eq("(Mp3Info Comment)[rus]: Здравствуйте dïáçrìtícs!")
  end

  it "should pretty-print TXXX frames in the style of id3v2" do
    user_text = "Here is some random user-defined text."
    new_tag = { "TXXX" => ID3V24::Frame.create_frame("TXXX", user_text) }
    saved_tag = update_id3_2_tag(@mp3_filename, new_tag)
    saved_frame = saved_tag['TXXX']

    expect(saved_frame.to_s_pretty).to eq("(Mp3Info Comment) : Here is some random user-defined text.")
  end

  it "should pretty-print WXXX frames in the style of id3v2" do
    user_link = "http://www.yourmom.gov"
    new_tag = { "WXXX" => ID3V24::Frame.create_frame("WXXX", user_link) }
    saved_tag = update_id3_2_tag(@mp3_filename, new_tag)
    saved_frame = saved_tag['WXXX']

    expect(saved_frame.to_s_pretty).to eq("(Mp3Info User Link) : http://www.yourmom.gov")
  end

  it "should pretty-print TCON frames (genre name) id3v2 style, as 'Name (id)'" do
    genre_name = "Jungle"
    tag = { "TCON" => ID3V24::Frame.create_frame("TCON", genre_name) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    saved_frame = saved_tag['TCON']

    expect(saved_frame.to_s_pretty).to eq("Jungle (63)")
  end

  it "should pretty-print TCON frames (genre name) id3v2 style, as 'Name (255)'" do
    genre_name = "Experimental"
    tag = { "TCON" => ID3V24::Frame.create_frame("TCON", genre_name) }
    saved_tag = update_id3_2_tag(@mp3_filename, tag)
    saved_frame = saved_tag['TCON']

    expect(saved_frame.to_s_pretty).to eq("Experimental (255)")
  end
end
