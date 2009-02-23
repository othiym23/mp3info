require 'digest/sha1'

require 'mp3info/id3'
require 'mp3info/mpeg_utils'

class MP3Excerpter
  GRABBINATE_SIZE = 2**16
  
  def initialize(path, output_directory)
    @path = path
    @output_directory = output_directory
  end
  
  def dump_excerpt
    id3v2 = id3 = frames = ''
    
    io = File.new(@path, "rb")
    header = io.read(3)
    io.seek(0)
    
    if header == 'ID3'
      id3v2 = grab_id3v2(io)
    end
    
    frames = grab_mpeg_data(io)
    io.close
    
    if ID3.has_id3v1_tag?(@path)
      id3 = grab_id3(@path)
    end
    
    excerpt = id3v2 + frames + id3
    filename = "#{Digest::SHA1.hexdigest(excerpt)}.mp3"
    
    $stderr.puts "Writing excerpt of #{@path} to #{File.expand_path(@output_directory)}/#{filename}"
    unless File.exist?(@output_directory)
      $stderr.puts("#{File.expand_path(@output_directory)} does not exist, creating it.\n\n")
      FileUtils.mkdir(@output_directory)
    end
    File.open("#{File.expand_path(@output_directory)}/#{filename}", "w") { |file| file.write(excerpt) }
    
    filename
  end
  
  private
  
  # take no prisoners ID3v2 grabbing
  def grab_id3v2(io)
    # ID3v2 tag grabbing
    raw_tag = io.read(6)
    
    tag_length_synchsafe = io.read(4)
    raw_tag << tag_length_synchsafe
    
    tag_length = tag_length_synchsafe.from_synchsafe_string
    remaining_bytes = io.stat.size - io.pos
    
    if remaining_bytes >= tag_length
      $stderr.puts("    Reading #{tag_length} ID3 bytes from #{@path} starting at #{"%06x" % (io.pos - 10)}.")
      raw_tag << io.read(tag_length)
    else
      $stderr.puts("    Reading #{remaining_bytes} remaining ID3 bytes from #{@path} starting at #{"%06x" % io.pos}.")
      raw_tag << io.read(remaining_bytes)
    end
    
    raw_tag
  end
  
  # take no prisoners MPEG audio grabbing -- rip the first 64K under the seek position
  def grab_mpeg_data(io)
    data = ''
    
    begin
      remaining_bytes = io.stat.size - io.pos
      if io.stat.size - io.pos > 0
        # just in case, don't want to grab ID3 tag twice
        remaining_bytes = io.stat.size - io.pos - 128
        size_to_grab = [GRABBINATE_SIZE, remaining_bytes].min
        
        $stderr.puts("    Grabbing #{size_to_grab} bytes from #{@path} starting at #{"%06x" % io.pos} (#{remaining_bytes} left).")
        data = io.read(size_to_grab)
      end
    rescue Exception => cause
      $stderr.puts("WARN: Exception: #{cause}. Couldn't read frames.")
    end
    
    data
  end
  
  # take no prisoners ID3 copying
  def grab_id3(path)
    File.open(path, "rb") do |file|
      file.seek(-128, IO::SEEK_END)
      file.read(128)
    end
  end
end
