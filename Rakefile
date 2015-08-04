require_relative 'lib/wire'

task :build do
  system 'gem build wire.gemspec'
end

task :release => :build do
  system "gem push wire-#{WikiThis::VERSION}.gem"
end