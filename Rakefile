require 'rake'
require 'spec/rake/spectask'

desc "Run all examples"
Spec::Rake::SpecTask.new('spec')

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('spec:rcov') do |t|
  t.rcov = true
  t.rcov_opts = ['-x', 'spec/,/Library/Ruby/Gems/1.8/gems']
end

desc "Generate RCov reports for just the MPEG utiltity class"
Spec::Rake::SpecTask.new('spec:rcov:mpeg_utils') do |t|
  t.spec_files = FileList['spec/mpeg_utils_spec.rb']
  t.rcov = true
  t.rcov_opts = ['-x', 'spec/,/Library/Ruby/Gems/1.8/gems']
end

desc "Generate RCov reports for just the ID3 class"
Spec::Rake::SpecTask.new('spec:rcov:id3v1') do |t|
  t.spec_files = FileList['spec/id3/basic_spec.rb']
  t.rcov = true
  t.rcov_opts = ['-x', 'spec/,/Library/Ruby/Gems/1.8/gems']
end

desc "Generate RCov reports for just the ID3v2 class"
Spec::Rake::SpecTask.new('spec:rcov:id3v2') do |t|
  t.spec_files = FileList['spec/id3v2/basic_spec.rb']
  t.rcov = true
  t.rcov_opts = ['-x', 'spec/,/Library/Ruby/Gems/1.8/gems']
end
