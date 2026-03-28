$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.join(File.dirname(__FILE__)))

require 'mp3info/mp3info_helper'

RSpec.configure do |config|
  config.include Mp3InfoHelper
end
