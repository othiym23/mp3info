Gem::Specification.new do |s|
  s.name = "mp3info"
  s.version = "0.8.0"
  s.summary = "Pure Ruby library for reading and writing MP3 metadata"
  s.description = "Read and write ID3v1, ID3v2 (2.2/2.3/2.4) tags, MPEG headers, " \
                  "Xing/LAME headers, and ReplayGain information from MP3 files. " \
                  "Pure Ruby with no external dependencies."
  s.authors = ["Rei Moribito", "Guillaume Pierronnet"]
  s.email = ["othiym23@gmail.com"]
  s.homepage = "https://github.com/ogd/mp3info"
  s.license = "Ruby"

  s.required_ruby_version = ">= 3.1"

  s.files = Dir[
    "lib/**/*.rb",
    "lib/mp3info/*.yml",
    "bin/*",
    "CHANGELOG",
    "EXAMPLES",
    "README"
  ]
  s.require_paths = ["lib"]
  s.executables = ["mp3qa"]

  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "standard", "~> 1.54"
end
