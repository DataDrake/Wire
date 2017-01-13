##
# Copyright 2017 Bryan T. Meyers
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
Gem::Specification.new do |s|
  s.name        = 'wire-framework'
  s.version     = Wire::VERSION
  s.date        = '2017-01-13'
  s.summary     = 'Wire Framework'
  s.description = 'Wire is a DSL and Rack interface for quickly building web applications, without the needless complexity of Rails'
  s.authors     = ['Bryan T. Meyers']
  s.email       = 'bmeyers@datadrake.com'
  s.files       = Dir.glob('lib/**/*') + %w(LICENSE README.md)
  s.homepage    = 'http://rubygems.org/gems/wire'
  s.license     = 'Apache-2.0'
  s.add_runtime_dependency 'awesome_print'
  s.add_runtime_dependency 'cobravsmongoose'
  s.add_runtime_dependency 'lmdb'
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'nori'
  s.add_runtime_dependency 'sequel'
  s.add_runtime_dependency 'rack'
  s.add_runtime_dependency 'rest-less'
  s.add_runtime_dependency 'tilt'
end