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

require 'json'

# The Ruby-Core JSON module
module JSON

  # Force JSON.parse to symbolize names
  # @param [String] source the raw JSON string
  # @param [Hash] opts any further options for JSON.parse
  # @return [Hash] the parsed JSON content
  def self.parse_clean(source, opts = {})
    opts[:symbolize_names] = true
    parse(source, opts)
  end
end

# Wire is an environment for quickly building REST services
# @author Bryan T. Meyers
module Wire
  # Current version of the Wire Gem
  VERSION = '0.1.6.6'
end

require_relative 'app'
require_relative 'closet'
