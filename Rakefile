require_relative 'lib/wire'

task :build do
  system 'gem build wire.gemspec'
end

task :install => :build do
  system "sudo gem install -N -l wire-#{Wire::VERSION}.gem"
end

task :release => :build do
  system "gem push wire-#{Wire::VERSION}.gem"
end