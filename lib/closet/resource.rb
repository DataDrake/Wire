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

	# Resource is a DSL function for mapping sub-URI in Wire::App(s)
	# @author Bryan T. Meyers
	module Resource

		# Setup a Renderer
		# @param [String] uri the sub-URI
		# @param [Proc] block for configuring this resource
		# @return [void]
		def resource(uri, &block)
			$current_app[:resources][uri] = {}
			$current_resource             = $current_app[:resources][uri]
			if ENV['RACK_ENV'].eql? 'development'
				$stderr.puts "Starting Resource At: /#{$current_uri + '/' + uri}"
			end
			Docile.dsl_eval(self, &block)
		end
	end
end