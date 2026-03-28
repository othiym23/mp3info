$LOAD_PATH.unshift(File.join(__dir__, "..", "lib"))
$LOAD_PATH.unshift(__dir__)

require "mp3info/mp3info_helper"

RSpec.configure do |config|
  config.include Mp3InfoHelper
end
