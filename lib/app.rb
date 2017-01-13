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

module Wire
	# App is a DSL function for mapping sub-URI to Wire::App(s)
	# @author Bryan T. Meyers
	module App

		# Setup an App
		# @param [String] base_uri the sub-URI
		# @param [Module] type the Wire::App
		# @param [Proc] block for configuring this App
		# @return [void]
		def app(base_uri, type, &block)
			$current_uri    = base_uri
			$apps[base_uri] = { type: type, resources: {} }
			$current_app    = $apps[base_uri]
			if ENV['RACK_ENV'].eql? 'development'
				$stderr.puts "Starting App at: /#{base_uri}"
				$stderr.puts 'Setting up resources...'
			end
			Docile.dsl_eval(type, &block)
		end
	end
end

require_relative 'app/cache'
require_relative 'app/db'
require_relative 'app/file'
require_relative 'app/login'
require_relative 'app/history'
require_relative 'app/render'
require_relative 'app/repo'