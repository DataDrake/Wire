##
# Copyright 2017-2018 Bryan T. Meyers
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.
##

require_relative 'lib/wire'

task :build do
  system 'gem build wire.gemspec'
end

task :install => :build do
  system "sudo gem install -N -l wire-framework-#{Wire::VERSION}.gem"
end

task :release => :build do
  system "gem push wire-framework-#{Wire::VERSION}.gem"
end