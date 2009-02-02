require 'rake'
require 'spec/rake/spectask'

desc "Run all examples"
Spec::Rake::SpecTask.new('spec')

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('spec:rcov') do |t|
  t.rcov = true
  t.rcov_opts = ['-x', 'spec/,/Library/Ruby/Gems/1.8/gems']
end
