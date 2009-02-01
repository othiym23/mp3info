require 'rake'
require 'spec/rake/spectask'

desc "Run all examples"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['mp3info_behavior.rb']
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('spec:rcov') do |t|
  t.spec_files = FileList['mp3info_behavior.rb']
  t.rcov = true
  t.rcov_opts = ['-x', 'mp3info_behavior.rb,/Library/Ruby/Gems/1.8/gems']
end
